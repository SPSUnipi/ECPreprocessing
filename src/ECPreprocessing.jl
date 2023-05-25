using XLSX
using YAML
using CSV
using DataFrames

# Define the file path
general_path = @__DIR__
relative_path_GSE = "../data/GSE_prelievo.xlsx"
file_GSE= joinpath(general_path,relative_path_GSE)

# Read data from the first sheet
#sheet_name = XLSX.sheetnames(file_GSE)
GSE_profiles= DataFrame(XLSX.readtable(file_GSE,"Foglio1"))

# read YAML file
yaml_file_name = "../data/energy_community_model.yml"
file_YAML = joinpath(@__DIR__,yaml_file_name)
config = YAML.load_file(file_YAML)
yaml_file_out = "output/processed_energy_community_model.yml"

# definition of main parameters
final_step = 8760 #or any other time res resolution
start_users_residential = 1
end_users_residential = 3
start_users_other_uses = 4
end_users_other_uses = 9
residential_yearly = fill(2700,end_users_residential)
residential_yearly_distribution = [0.098,	0.083,0.087,	0.078,	0.075	,0.073,	0.079,	0.078,	0.074	,0.084,	0.088	,0.103]
other_uses_yearly = fill(3400,end_users_other_uses-start_users_other_uses+1)
consumption_yearly = vcat(residential_yearly,other_uses_yearly)

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
        "max_capacity" => 6,
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

non_residential_components = Dict(
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
    
for i = start_users_residential: end_users_residential
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

for i = start_users_other_uses : end_users_other_uses
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
for i = start_users_residential: end_users_other_uses
    label = "load_user$i"
    if i < start_users_other_uses
        code = Symbol("PDMM")
        yearly_consumption_vector = fill(consumption_yearly[i],final_step)
        segments_user = [yearly_consumption_vector[Int(j):Int(j+(final_step/12-1))] for j in 1:(final_step/12):final_step]
        user_residential_monthly = [segment .* number for (segment, number) in zip(segments_user, residential_yearly_distribution)]
        user_residential_monthly = reduce(vcat, user_residential_monthly)
        user_load_y= user_residential_monthly.*GSE_profiles[:,code]
        input_dataframe[!,label] = user_load_y
    end
    if i > end_users_residential
        code = Symbol("PAUM")
        user_other_uses_monthly = fill(consumption_yearly[i]/12,final_step)
        user_load_y= user_other_uses_monthly.*GSE_profiles[:,code]
        input_dataframe[!,label] = user_load_y
    end
end


# create a CSV file named "filename.csv" with a header row and the values in the array
CSV.write("output/input_resources.csv", input_dataframe)


# write updated configuration to YAML file
YAML.write_file(yaml_file_out, config)