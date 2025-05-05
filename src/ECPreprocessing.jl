using XLSX
using YAML
using CSV
using DataFrames
using Revise
using Pkg

Pkg.activate("Project.toml")

include("functions.jl")

# Percorsi e parametri principali
general_path = @__DIR__
relative_path_GSE = "../data/GSE_prelievo.xlsx"
file_GSE = joinpath(general_path, relative_path_GSE)
yaml_file_name = "../data/energy_community_model.yml"
file_YAML = joinpath(@__DIR__, yaml_file_name)
config = YAML.load_file(file_YAML)
output_dir = "output"

# Componenti e parametri definiti
components = ["tariff_name", "PV", "batt", "conv", "load"]
residential_components = Dict(
    "tariff_name" => "non_commercial"
    ,
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
    "wind" => Dict(
        "type" => "renewable",
        "CAPEX_lin" => 300,
        "OEM_lin" => 30,
        "lifetime_y" => 20,
        "max_capacity" => 100,
        "profile" => Dict(
            "ren_pu" => "wind"
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

# Genera file YAML per 10, 20, 30 e 50 utenti
user_counts = [10, 30, 50]

# Percentuali di prosumer da testare
prosumer_percentages = [10, 20, 50, 70, 100]

# Percentuali di variazione "Noise" da testare
noise_percentages = [10, 20]

# Carica i dati dal file YAML di base
data = YAML.load_file("data/energy_community_model.yml")
unique_assets = extract_unique_assets(data)

# Carica i dati di input_resource.csv
input_resource_path = joinpath(general_path, "../data/input_resource.csv")
input_resource = CSV.read(input_resource_path, DataFrame)

# Aggiungi colonne con rumore
input_resource = add_noise_to_csv(input_resource, noise_percentages)

# Salva il file CSV aggiornato (opzionale, se vuoi salvare le modifiche)
CSV.write(input_resource_path, input_resource)

# Genera file YAML per ogni scenario
generate_scenario_files(user_counts, prosumer_percentages, noise_percentages, components, residential_components, config, output_dir, unique_assets, input_resource)

# Genera file YAML per ogni scenario
global total_simulations = 0

for user_count in user_counts
    for prosumer_percentage in prosumer_percentages
        # Genera scenari Mixed
        if prosumer_percentage in [20, 50, 70, 100]
        generate_single_scenario(user_count, prosumer_percentage, "Mixed", config, output_dir, components, residential_components, unique_assets, input_resource)
        global total_simulations += 1
        end

        # Genera scenari Identical
        if user_count in [10, 30] && prosumer_percentage in [20, 50, 70, 100]
            generate_single_scenario(user_count, prosumer_percentage, "Identical", config, output_dir, components, residential_components, unique_assets, input_resource)
            global total_simulations += 1
        end

        # Genera scenari Identical con Noise
        if user_count in [10, 30] && prosumer_percentage in [20, 70]
            for noise_percentage in noise_percentages
                generate_single_scenario(user_count, prosumer_percentage, "Noise", config, output_dir, components, residential_components, unique_assets, input_resource, noise_percentage)
                global total_simulations += 1
            end
        end

        # Genera scenari Identical-inf con Noise
        if user_count in [10, 30] && prosumer_percentage == 10
            for noise_percentage in noise_percentages
                generate_single_scenario(user_count, prosumer_percentage, "Identical-inf", config, output_dir, components, residential_components, unique_assets, input_resource, noise_percentage)
                global total_simulations += 1
            end
        end
    end
end

println("Total simulations: $total_simulations")