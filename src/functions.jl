# Funzione per creare utenti
function create_users(start_residential, end_residential, start_other, end_other, components, residential_components)
    users = Dict()
    user_set = []  # Lista per memorizzare i nomi degli utenti

    for i in start_residential:end_residential
        user_name = "user$i"
        push!(user_set, user_name)  # Aggiungi il nome utente alla lista
        users[user_name] = Dict()
        for component in components
            users[user_name][component] = deepcopy(residential_components[component])
            if component == "load"
                users[user_name][component]["profile"]["load"] = "load_user$i"
            end
        end
    end

    for i in start_other:end_other
        user_name = "user$i"
        push!(user_set, user_name)  # Aggiungi il nome utente alla lista
        users[user_name] = Dict()
        for component in components
            users[user_name][component] = deepcopy(residential_components[component])
            if component == "load"
                users[user_name][component]["profile"]["load"] = "load_user$i"
            end
        end
    end

    return users, user_set
end

# Funzione per creare utenti con percentuale di prosumer
function create_users_with_prosumers(start_residential, end_residential, start_other, end_other, components, residential_components, prosumer_percentage)
    users = Dict()
    user_set = []  # Lista per memorizzare i nomi degli utenti
    total_users = end_residential - start_residential + 1 + end_other - start_other + 1
    num_prosumers = Int(round(total_users * prosumer_percentage / 100))

    # Crea utenti residenziali
    for i in start_residential:end_residential
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()
        for component in components
            if component in ["PV", "batt", "conv"] && i > num_prosumers
                continue  # Escludi asset di produzione per utenti non prosumer
            end
            users[user_name][component] = deepcopy(residential_components[component])
            if component == "load"
                users[user_name][component]["profile"]["load"] = "load_user$i"
            end
        end
    end

    # Crea utenti non residenziali
    for i in start_other:end_other
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()
        for component in components
            if component in ["PV", "batt", "conv"] && i > num_prosumers
                continue  # Escludi asset di produzione per utenti non prosumer
            end
            users[user_name][component] = deepcopy(residential_components[component])
            if component == "load"
                users[user_name][component]["profile"]["load"] = "load_user$i"
            end
        end
    end

    return users, user_set
end

# Funzione per creare utenti "Identical"
function create_identical_prosumers(user_count, prosumer_percentage, components, residential_components)
    users = Dict()
    user_set = []
    total_prosumers = Int(round(user_count * prosumer_percentage / 100))
    total_profiles = 10  # Number of available profiles (load_user1 to load_user10)

    for i in 1:user_count
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()

        # Add identical assets for prosumers
        if i <= total_prosumers
            for component in ["PV", "batt", "wind", "conv"]
                users[user_name][component] = deepcopy(residential_components[component])
            end
        end

        # Add the load profile, cycling every 10 users
        base_profile_index = mod(i - 1, total_profiles) + 1
        users[user_name]["load"] = deepcopy(residential_components["load"])
        users[user_name]["load"]["profile"]["load"] = "load_user$base_profile_index"
    end

    return users, user_set
end

# Funzione per creare utenti "Mixed"
function create_mixed_prosumers(user_count, prosumer_percentage, components, residential_components, unique_assets)
    users = Dict()
    user_set = []
    total_prosumers = Int(round(user_count * prosumer_percentage / 100))
    asset_index = 1
    total_profiles = 10  # Number of available profiles (load_user1 to load_user10)

    for i in 1:user_count
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()

        # Add unique assets for prosumers
        if i <= total_prosumers
            for component in unique_assets[asset_index]
                users[user_name][component] = deepcopy(residential_components[component])
            end
            asset_index = mod(asset_index, length(unique_assets)) + 1
        end

        # Add the load profile, cycling every 10 users
        base_profile_index = mod(i - 1, total_profiles) + 1
        users[user_name]["load"] = deepcopy(residential_components["load"])
        users[user_name]["load"]["profile"]["load"] = "load_user$base_profile_index"
    end

    return users, user_set
end

# Funzione per creare utenti "Identical-inf"
function create_identical_inf_prosumers(user_count, prosumer_percentage, components, residential_components)
    users = Dict()
    user_set = []
    total_prosumers = Int(round(user_count * prosumer_percentage / 100))
    total_profiles = 10  # Number of available profiles (load_user1 to load_user10)

    for i in 1:user_count
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()

        # Add identical assets without capacity limits for prosumers
        if i <= total_prosumers
            for component in ["PV", "batt", "wind", "conv"]
                users[user_name][component] = deepcopy(residential_components[component])
                users[user_name][component]["max_capacity"] = nothing  # Remove capacity limit
            end
        end

        # Add the load profile, cycling every 10 users
        base_profile_index = mod(i - 1, total_profiles) + 1
        users[user_name]["load"] = deepcopy(residential_components["load"])
        users[user_name]["load"]["profile"]["load"] = "load_user$base_profile_index"
    end

    return users, user_set
end

# Funzione per creare utenti con variazione "Noise"
function create_users_with_noise(user_count, noise_percentage, components, residential_components, input_resource)
    users = Dict()
    user_set = []
    total_profiles = 10  # Numero di profili disponibili (load_user1 a load_user10)

    for i in 1:user_count
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()

        # Determina il profilo di carico con rumore
        base_profile_index = mod(i - 1, total_profiles) + 1
        noisy_profile_name = "load_user$(base_profile_index)_noise_$noise_percentage"
        users[user_name]["load"] = deepcopy(residential_components["load"])
        users[user_name]["load"]["profile"]["load"] = noisy_profile_name

        # Aggiungi gli altri componenti senza variazioni
        for component in components
            if component != "load"
                users[user_name][component] = deepcopy(residential_components[component])
            end
        end
    end
    return users, user_set
end

# Funzione per creare utenti con profili replicati (caso base)
function create_users_base_case(user_count, components, residential_components)
    users = Dict()
    user_set = []
    total_profiles = 10  # Numero di profili disponibili

    for i in 1:user_count
        user_name = "user$i"
        push!(user_set, user_name)
        users[user_name] = Dict()

        # Determina il profilo di carico replicato
        base_profile_index = mod(i - 1, total_profiles) + 1
        replicated_profile_name = "load_user$base_profile_index"

        # Aggiungi il profilo di carico replicato
        users[user_name]["load"] = deepcopy(residential_components["load"])
        users[user_name]["load"]["profile"]["load"] = replicated_profile_name

        # Aggiungi gli altri componenti senza variazioni
        for component in components
            if component != "load"
                users[user_name][component] = deepcopy(residential_components[component])
            end
        end
    end

    return users, user_set
end

# Funzione per generare file YAML per diversi numeri di utenti e percentuali di prosumer
function generate_yaml_files_with_prosumers(user_counts, prosumer_percentages, components, residential_components, config, output_dir)
    for user_count in user_counts
        for prosumer_percentage in prosumer_percentages
            # Calcola i limiti per utenti residenziali e non residenziali
            start_users_residential = 1
            end_users_residential = div(user_count, 2)
            start_users_other_uses = end_users_residential + 1
            end_users_other_uses = user_count

            # Crea gli utenti con la percentuale di prosumer
            users, user_set = create_users_with_prosumers(
                start_users_residential,
                end_users_residential,
                start_users_other_uses,
                end_users_other_uses,
                components,
                residential_components,
                prosumer_percentage
            )

            # Aggiorna la configurazione
            config["general"]["user_set"] = user_set
            config["users"] = users

            # Scrivi il file YAML
            yaml_file_out = joinpath(output_dir, "energy_community_model_$(user_count)_$(prosumer_percentage).yml")
            YAML.write_file(yaml_file_out, config)
        end
    end
end

# Funzione per generare file YAML per ogni scenario, incluso "Noise" e il caso base
function generate_scenario_files(user_counts, prosumer_percentages, noise_percentages, components, residential_components, config, output_dir, unique_assets, input_resource)
    for user_count in user_counts
        for prosumer_percentage in prosumer_percentages
            generate_single_scenario(user_count, prosumer_percentage, "Mixed", config, output_dir, components, residential_components, unique_assets, input_resource)
            generate_single_scenario(user_count, prosumer_percentage, "Identical", config, output_dir, components, residential_components, unique_assets, input_resource)
            generate_single_scenario(user_count, prosumer_percentage, "Identical-inf", config, output_dir, components, residential_components, unique_assets, input_resource)
        end
        for noise_percentage in noise_percentages
            generate_single_scenario(user_count, 20, "Noise", config, output_dir, components, residential_components, unique_assets, input_resource, noise_percentage)
        end
    end
end

# Estrai combinazioni uniche di asset dai dati YAML
function extract_unique_assets(data)
    unique_assets = Set()  # Insieme per memorizzare combinazioni uniche di asset

    # Itera sugli utenti definiti nel file YAML
    for (user, assets) in data["users"]
        # Ottieni i nomi degli asset per l'utente, escludendo "load"
        asset_set = setdiff(Set(string.(keys(assets))), Set(["load"]))
        
        # Aggiungi la combinazione di asset all'insieme
        push!(unique_assets, asset_set)
    end

    # Restituisci le combinazioni uniche come lista
    return collect(unique_assets)
end

function add_noise_to_csv(input_resource, noise_percentages)
    for noise_percentage in noise_percentages
        for user in 1:10  # Supponendo che ci siano 10 utenti
            column_name = "load_user$user"
            noisy_column_name = "load_user$(user)_noise_$noise_percentage"
            input_resource[!, noisy_column_name] = input_resource[!, column_name] .* (1 .+ noise_percentage / 100 .* (2 .* rand(size(input_resource[!, column_name])) .- 1))
        end
    end
    return input_resource
end

function add_components_to_user(user_name, users, components, residential_components, profile_index; max_capacity=nothing)
    users[user_name] = Dict()
    for component in components
        users[user_name][component] = deepcopy(residential_components[component])
        if component == "load"
            users[user_name][component]["profile"]["load"] = "load_user$profile_index"
        elseif !isnothing(max_capacity) && haskey(users[user_name][component], "max_capacity")
            users[user_name][component]["max_capacity"] = max_capacity
        end
    end
end

function create_users_generic(user_count, prosumer_percentage, components, residential_components; unique_assets=nothing, noise_percentage=nothing, identical_inf=false)
    users = Dict()
    user_set = []
    total_prosumers = Int(round(user_count * prosumer_percentage / 100))
    total_profiles = 10  # Numero di profili disponibili
    asset_index = 1

    for i in 1:user_count
        user_name = "user$i"
        push!(user_set, user_name)
        profile_index = mod(i - 1, total_profiles) + 1

        if !isnothing(unique_assets) && i <= total_prosumers
            # Configurazione Mixed
            users[user_name] = Dict()
            for component in unique_assets[asset_index]
                users[user_name][component] = deepcopy(residential_components[component])
            end
            asset_index = mod(asset_index, length(unique_assets)) + 1
        elseif identical_inf && i <= total_prosumers
            # Configurazione Identical-inf
            add_components_to_user(user_name, users, components, residential_components, profile_index; max_capacity=nothing)
        elseif !isnothing(noise_percentage)
            # Configurazione con Noise
            noisy_profile_name = "load_user$(profile_index)_noise_$noise_percentage"
            add_components_to_user(user_name, users, components, residential_components, profile_index)
            users[user_name]["load"]["profile"]["load"] = noisy_profile_name
        else
            # Configurazione Identical o base
            add_components_to_user(user_name, users, components, residential_components, profile_index)
        end
    end

    return users, user_set
end

function generate_single_scenario(user_count, prosumer_percentage, scenario_type, config, output_dir, components, residential_components, unique_assets, input_resource, noise_percentage=nothing)
    if scenario_type == "Mixed"
        users, user_set = create_users_generic(user_count, prosumer_percentage, components, residential_components; unique_assets=unique_assets)
    elseif scenario_type == "Identical"
        users, user_set = create_users_generic(user_count, prosumer_percentage, components, residential_components)
    elseif scenario_type == "Identical-inf"
        users, user_set = create_users_generic(user_count, prosumer_percentage, components, residential_components; identical_inf=true)
    elseif scenario_type == "Noise"
        users, user_set = create_users_generic(user_count, prosumer_percentage, components, residential_components; noise_percentage=noise_percentage)
    else
        error("Scenario type non valido: $scenario_type")
    end

    config["general"]["user_set"] = YAML.Node(user_set, style=YAML.Style(flow=true))
    config["users"] = users
    yaml_file_out = joinpath(output_dir, "energy_community_model_$(user_count)_$(prosumer_percentage)_$(scenario_type).yml")
    YAML.write_file(yaml_file_out, config)
end