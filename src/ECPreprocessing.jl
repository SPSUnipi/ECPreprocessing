using XLSX
using YAML
using CSV
using DataFrames

# Define the file path
general_path = @__DIR__
relative_path_GSE = "GSE_prelievo.xlsx"
file_GSE= joinpath(general_path,relative_path_GSE)

# Read data from the first sheet
#sheet_name = XLSX.sheetnames(file_GSE)
GSE_profiles= XLSX.readdata(file_GSE,"Foglio1","A1:S8761")

# read YAML file
yaml_file_name = "energy_community_model.yml"
file_YAML = joinpath(@__DIR__,yaml_file_name)
config = YAML.load_file(file_YAML)
yaml_file_out = "Pre_processing/processed_energy_community_model.yml"

# definition of main parameters
final_step = 8760 #or any other time res resolution
n_users_residential = 3
n_users_other_uses = 4
residential_yearly = [2700, 3200, 4000]
other_uses = [1300, 2000, 1000, 4000]

# definition of residential and commercial compontens
residential_components = Dict(
    "market_set" => Dict(
        "market_type" => "non_commercial",
        "type" => "market"
    ),
    "PV" => Dict(
        "type" => "renewable",
        "CAPEX_lin" => 1500,
        "OEM_lin" => 30,
        "lifetime_y" => 25,
        "max_capacity" => 3,
        "profile" => Dict(
            "ren_pu" => "pv"
        )
    ),
    "batt" => Dict(
        "type" => "battery",
        "CAPEX_lin" => 400,
        "OEM_lin" => 5,
        "lifetime_y" => 15,
        "eta" => 0.92,
        "max_SOC" => 1.0,
        "min_SOC" => 0.2,
        "max_capacity" => 15,
        "max_C_dch" => 1.0,
        "max_C_ch" => 1.0,
        "corr_asset" => "conv"
    ),
    "conv" => Dict(
        "type" => "converter",
        "CAPEX_lin" => 200,
        "OEM_lin" => 2,
        "lifetime_y" => 10,
        "eta" => 1.0,
        "max_dch" => 1.0,
        "min_ch" => 0.1,
        "max_capacity" => 15,
        "corr_asset" => "batt"
    ),
    "load" => Dict(
        "type" => "load",
        "profile" => Dict(
            "load" => "load_user"
        )
    )
)
commercial_components = Dict(
    "market_set" => Dict(
        "market_type" => "commercial",
        "type" => "market"
    ),
    "PV" => Dict(
        "type" => "renewable",
        "CAPEX_lin" => 1400,
        "OEM_lin" => 30,
        "lifetime_y" => 25,
        "max_capacity" => 200,
        "profile" => Dict(
            "ren_pu" => "pv"
        )
    ),
    "batt" => Dict(
        "type" => "battery",
        "CAPEX_lin" => 400,
        "OEM_lin" => 5,
        "lifetime_y" => 15,
        "eta" => 0.92,
        "max_SOC" => 1.0,
        "min_SOC" => 0.2,
        "max_capacity" => 100,
        "max_C_dch" => 1.0,
        "max_C_ch" => 1.0,
        "corr_asset" => "conv"
    ),
    "conv" => Dict(
        "type" => "converter",
        "CAPEX_lin" => 200,
        "OEM_lin" => 2,
        "lifetime_y" => 10,
        "eta" => 1.0,
        "max_dch" => 1.0,
        "min_ch" => 0.1,
        "max_capacity" => 100,
        "corr_asset" => "batt"
    ),
    "load" => Dict(
        "type" => "load",
        "profile" => Dict(
            "load" => "load_user"
        )
    )
)

#Creation of new users set
users = Dict()
components = ["market_set","PV", "batt", "conv", "load"]
    
for i = 1: n_users_residential
    user_name = "user$i"
    users[user_name] = Dict()
    for component = components
        users[user_name][component] = deepcopy(residential_components[component])
        if component == "load"
            users[user_name][component]["profile"]["load"] = "load_user$i"
        end
    end
    push!(config["general"]["user_set"],user_name)
end

for i = 1 + n_users_residential : n_users_residential + n_users_other_uses
    user_name = "user$i"
    users[user_name] = Dict()
    for component = components
        users[user_name][component] = deepcopy(residential_components[component])
        if component == "load"
            users[user_name][component]["profile"]["load"] = "load_user$i"
        end
    end
    push!(config["general"]["user_set"],user_name)
end

config["users"] = users

#Creation of CSV file input_resource
# create an array with n rows and 1 column, filled with values from 1 to ntime_re
input_dataframe = DataFrame(time = [i for i in 1:final_step])

# create user profiles from type of users
for i = 1: n_users_residential
    residential_code = "PDMM"
    residential_monthly = residential_yearly/12
    label = "load_user$i"

end

for i = n_users_residential + 1 : n_users_other_uses + n_users_residential
    residential_code = "PAUM"
end


# create a CSV file named "filename.csv" with a header row and the values in the array
CSV.write("Pre_processing/input_resources.csv", input_dataframe)


# write updated configuration to YAML file
YAML.write_file(yaml_file_out, config)