/**
* Name: WasteManagement
* Based on the internal skeleton template. 
* Author: Patrick Taillandier
* Tags: 
*/

model WasteManagement

global {
	
	shape_file Limites_commune_shape_file <- shape_file("../includes/Shp_fictifs/Limites_commune.shp");

	shape_file Limites_urban_areas_shape_file <- shape_file("../includes/Shp_fictifs/Limites_villages.shp");

	shape_file Hydrologie_shape_file <- shape_file("../includes/Shp_fictifs/Hydrologie.shp");

	geometry shape <- envelope(Limites_commune_shape_file);
	
	shape_file villages_shape_file <- shape_file("../includes/Shp_fictifs/Territoires_villages.shp");

	float step <- 1#day;
	float treatment_factory_capacity <- 2.0;
	
	float house_size <- 200.0 #m;
	float plot_size <- 500.0 #m;
	
	float field_initial_productivity <- 100.0; // initial productivity of fields;
	float distance_to_canal_for_pollution_impact <- 50 #m; //all the fields at this distance are impacted by the canal pollution
	float canal_solid_waste_pollution_impact_rate <- 0.01; //production (yield) = production  - (pollution of the surrounding canal * pollution_impact_rate)
	float canal_water_waste_pollution_impact_rate <- 0.01; //production (yield) = production  - (pollution of the surrounding canal * pollution_impact_rate)
	float ground_solid_waste_pollution_impact_rate <- 0.01; //production (yield) = production  - (sum solid pollution on cell * pollution_impact_rate)
	float ground_water_waste_pollution_impact_rate <- 0.01; //production (yield) = production  - (sum water pollution on cell * pollution_impact_rate)
	
	float quantity_from_local_to_communal_landfill <- 100.0; 
	float quantity_communal_landfill_to_treatment <- 200.0;
	
	float local_landfill_waste_pollution_impact_rate <- 0.0001; 
	float communal_landfill_waste_pollution_impact_rate <- 0.0001; 
	float distance_to_local_landfill_for_pollution_impact <- 2 #km;
	float distance_to_communal_landfill_for_pollution_impact <- 5 #km;
	
	
	float ground_water_pollution_reducing_day <- 0.01; //quantity of the ground water pollution that disapear every day
	float ground_solid_pollution_reducing_day <- 0.001; //quantity of the solid water pollution that disapear every day
	
	float water_waste_year_inhabitants <- 38500.0 / 1000.0;// L/pers/year
	float solid_waste_year_inhabitants <-  220.0;//kg/pers/year
	
	float water_waste_year_farmers <- 30000.0 / 1000.0;// L/pers/year
	float solid_waste_year_farmers <-  220.0;//kg/pers/year
	
	float part_solid_waste_canal_inhabitants <- 0.0;
	float part_water_waste_canal_inhabitants <- 1.0;
	
	float part_solid_waste_canal_farmers <- 0.5;
	float part_water_waste_canal_farmers <- 0.5;
	
	float token_weak_waste_collection <- 20.0; //tokens/year
	float token_strong_waste_collection <- 40.0; //tokens/year
	int collect_per_week_weak <- 2;
	int collect_per_week_strong <- 4;
	float collection_team_collection_capacity_day <- 100.0; //quantity of solid waste remove during 1 day of work
	
	
	float token_trimestrial_collective_action <- 25.0; //per year
	float impact_trimestrial_collective_action <- 0.3; //part of the solid waste remove from the canal
	
	float token_drain_dredge <- 60.0; //per action
	float impact_drain_dredge_waste <- 0.43; //part of the solid waste remove from the canal
	float impact_drain_dredge_agriculture <- 0.2; //improvment of the agricultural production
	
	float token_install_filter_for_homes_construction <- 200.0 ; //construction
	float token_install_filter_for_homes_maintenance <- 20.0 ; //per year	
	float token_sensibilization <- 15.0; //per year
	
	float token_pesticide_reducing <- 30.0; //per year
	float impact_pesticide_reducing_production  <- 0.15; //decrease of the agricultural production
	float impact_pesticide_reducing_waste  <- 0.33; //decrease waste production from farmers
	
	float token_implement_fallow <- 25.0; //per year
	float impact_implement_fallow  <- 0.33; //decrease the agricultural production
	
	float token_support_manure_buying <- 30.0; //per year
	float impact_support_manure_buying_production  <- 0.15; //improvment of the agricultural production
	float impact_support_manure_buying_waste  <- 0.2; //increase wastewater production
	
	float token_farmer_training <- 10.0; //per year
	float impact_farmer_training  <- 0.1; //improvment of the agricultural production
	
	float token_support_digital_tools <- 20.0; //per year
	float impact_support_digital_tools <- 0.15; //improvment of the agricultural production
	
	float min_display_waste_value <- 0.2;
	float coeff_cell_pollution_display <- 0.01;
	float coeff_visu_canal <- 3.0;
	
	string PLAYER_TURN <- "player turn";
	string COMPUTE_INDICATORS <-  "compute indicators";
	string ACT_BUILD_BINS <- "build bins";
	string ACT_BUILD_TREATMENT_FACTORY <- "build treatment factory";
	string ACT_END_OF_TURN <- "end of turn";

	float budget_year_per_people <- 1.0;
	float increase_urban_area_population_year <- 0.1;

	
	float rate_diffusion_liquid_waste <- 10.0; //rate of liquid waste per perimeter of canals passing to the the downstream canal
	float rate_diffusion_solid_waste <- 1.0;//rate of solid waste per perimeter of canals passing to the the downstream canal

	int end_of_game <- 8;
	list<rgb> village_color <- [#magenta, #gold, #violet,#orange];
	
	bool without_player <- false; //for testing
	
	
	string stage <-COMPUTE_INDICATORS;
	
	
	int index_player <- 0;
	date computation_end;
	
	//current action type
	int action_type <- -1;	
	
	communal_landfill the_communal_landfill;
	
	list<string> actions_name <- [
		ACT_BUILD_BINS,
		ACT_BUILD_TREATMENT_FACTORY,
		ACT_END_OF_TURN		
	]; 
	
	
	int turn <- 0;
	
	init {
		create village from: villages_shape_file sort_by (location.x + location.y * 2);
		create canal from: split_lines(Hydrologie_shape_file) {
			if (first(shape.points).x + (2 * first(shape.points).y)) > (last(shape.points).x + 2 * last(shape.points).y){
				shape <- line(reverse(shape.points));
			} 
		}
	
		graph canal_network <- directed(as_edge_graph(canal));
		ask canal {
			downtream_canals<- list<canal>(canal_network out_edges_of (canal_network target_of self));	
		}
		
		geometry free_space <- copy(shape);
		
		create commune from: Limites_commune_shape_file {
			free_space <- copy(shape);
		}
		list<geometry> uas;
		create urban_area from: Limites_urban_areas_shape_file;
		ask urban_area {
			list<geometry> geoms <- to_squares (shape,house_size);
			free_space <- free_space - shape;
			float nb <- 0.0;
			create house from: geoms {
				create inhabitant {
					location <- myself.location;
					my_house <- cell(location);
					my_cells <- cell overlapping myself;
					closest_canal <- canal closest_to self;
					nb <- nb + nb_people;
				}
			}
			population <- nb;
		
		} 
		
		
		list<geometry> ps <- to_squares (free_space,plot_size);
		

		create plot from: ps {
			closest_canal <- canal closest_to self;
			my_cells <- cell overlapping self;
			the_village <- village closest_to self;
			create farmer {
				myself.the_farmer <- self;
				closest_canal <- myself.closest_canal;
				location <- myself.location;
				my_house <- cell(location);
				my_cells <- myself.my_cells;	
			}
			the_communal_landfill <- first(communal_landfill at_distance distance_to_communal_landfill_for_pollution_impact);
			the_local_landfill <- first(local_landfill at_distance distance_to_local_landfill_for_pollution_impact);
		 	impacted_by_canal <- (self distance_to closest_canal) <= distance_to_canal_for_pollution_impact;
		}
		
	
		create communal_landfill {
			shape <- square(200) ;
			location <- any_location_in(first(commune).shape.contour);
			the_communal_landfill <- self;
		}
		
			
		
		ask cell {do update_color;}
		ask village {
			plots <- plot overlapping self;
			cells <- cell overlapping self;
			canals <- canal at_distance 1.0;
			inhabitants <- (inhabitant overlapping self) + (farmer overlapping self);
			population <- inhabitants sum_of each.nb_people;
			
			ask urban_area overlapping self {
				my_villages << myself;
			}
			create collection_team with:(my_village:self) {
				myself.collection_teams << self;
			}
			create local_landfill with:(my_village:self){
				
				location <- any_location_in(myself);
				myself.my_local_landfill <- self;
			}
		}
		computation_end <- current_date add_years 1;
	}
	
	action activate_act {
		if stage = PLAYER_TURN {
			button selected_but <- first(button overlapping (circle(1) at_location #user_location));
			if(selected_but != nil) {
				ask selected_but {
					ask button {bord_col<-#black;}
					if (action_type != id) {
						action_type<-id;
						bord_col<-#red;
						ask myself {do act_management();}
					} else {
						action_type<- -1;
					}
					
				}
			}
		}
	}
	
	action act_management {
		switch action_type {
			match 2 {ask village[index_player] {do end_of_turn;}}
		}
	}
	
	action manage_flow_canal {
		ask canal {
			do init_flow;
		}
		ask canal {
			do flow;
		}
		ask canal {
			do update_waste;
		}	
	}
	
	action manage_individual_pollution {
		ask farmer + inhabitant{
			do domestic_waste_production;
		}
		ask plot {
			do pollution_due_to_practice;
		}
	}
	
	action manage_daily_indicator {
		ask plot {
			do compute_productivity;
		}
		
		ask cell {
			do update_color;
		}
		ask village {do compute_indicators;}
	}
	
	action manage_landfill {
		ask local_landfill {
			do transfert_waste_to_communal_level;
		}
		ask communal_landfill {
			do manage_waste;
		}
	}
	
	action manage_end_of_indicator_computation {
		if (current_date >= computation_end) {
			stage <- PLAYER_TURN;
			index_player <- 0;
			step <- 0.0001;
			ask village {
				budget <- budget_year_per_people * population;
			}
			ask village {
				actions_done <- [];
				is_drained <- false;
			}
			turn <- turn + 1;
			if turn >= end_of_game {
				do pause;
			}
			else if not without_player {
				do tell("PLAYER TURN");
				do tell("PLAYER 1 TURN");
			}
		
			
		}
	}
	
	action manage_pollution_decrease {
		ask cell {
			do natural_pollution_reduction;
		}
		ask collection_team {
			do collect_waste;
		}
	}
	
	action increase_urban_area {
		ask urban_area {
			list<plot> neighbors_plot <- plot at_distance 0.1;
			if not empty(neighbors_plot) {
				float target_pop <- population *(1 + increase_urban_area_population_year);
				loop while: not empty(neighbors_plot) and population <target_pop {
					plot p <- one_of(neighbors_plot);
					p >> neighbors_plot;
					if (dead(p)) {break;}
					geometry shape_plot <- copy(p.shape);
					ask my_villages {inhabitants >> p.the_farmer; plots >> p;}
					shape <- shape + shape_plot;
					ask p.the_farmer {do die;}
					ask p {do die;}
					list<geometry> geoms <- to_squares (p,house_size);
					float nb <- 0.0;
					create house from: geoms {
						create inhabitant {
							location <- myself.location;
							my_house <- cell(location);
							my_cells <- cell overlapping myself;
							closest_canal <- canal closest_to self;
							nb <- nb + nb_people;
						}
					}
					population <- population + nb;
					
				}
			}
		}
	}
	
	reflex indicators_computation when: stage = COMPUTE_INDICATORS {
		do manage_individual_pollution;
		do manage_flow_canal;
		do manage_pollution_decrease;
		do manage_landfill;
		do manage_daily_indicator;
		do manage_end_of_indicator_computation;
	}
	
	reflex playerturn when: stage = PLAYER_TURN{
		if without_player or index_player >= length(village) {
			stage <- COMPUTE_INDICATORS;
			current_date <- computation_end;
			computation_end <- computation_end add_years 1;
			step <- #day;
			
			if not without_player {do tell("INDICATOR COMPUTATION");}
			do increase_urban_area;
		}
	}
}


grid button width:3 height:3 
{
	int id <- int(self);
	rgb bord_col<-#black;
	aspect normal {
		draw rectangle(shape.width * 0.8,shape.height * 0.8).contour + (shape.height * 0.01) color: bord_col;
		draw actions_name[id] font: font("Helvetica", 20 , #bold) color: #white;
	}
}



grid cell height: 50 width: 50 {
	float solid_waste_level <- 0.0 min: 0.0;
	float water_waste_level <- 0.0 min: 0.0;
	float pollution_level <- 0.0;
	
	action natural_pollution_reduction {
		if solid_waste_level > 0 {
			solid_waste_level <- solid_waste_level - ground_solid_waste_pollution_impact_rate;
		}
		if water_waste_level > 0 {
			water_waste_level <- water_waste_level - ground_water_waste_pollution_impact_rate;
		}
	}
	action update_color {
		pollution_level <- (water_waste_level + solid_waste_level) * coeff_cell_pollution_display;
		color <- rgb(255 * pollution_level, 255 * (1.0 - pollution_level),  0);
	} 
	
	aspect default {
		if pollution_level > min_display_waste_value {
			draw shape color: color;
		}
	}
	
}

species village {
	rgb color <- village_color[int(self)];
	list<string> actions_done;
	list<cell> cells;
	list<canal> canals;
	list<inhabitant> inhabitants;
	local_landfill my_local_landfill;
	float budget;
	float solid_pollution_level ;
	float water_pollution_level;
	float productivity_level min: 0.0;
	list<collection_team> collection_teams;
	float bonus_agricultural_production;
	list<plot> plots;
	float population;
	bool is_drained <- false;
	
	
	action compute_indicators {
		solid_pollution_level <- ((cells sum_of each.solid_waste_level) + (canals sum_of (each.solid_waste_level))) / 10000.0;
		water_pollution_level <- ((cells sum_of each.water_waste_level) + (canals sum_of (each.water_waste_level)))/ 10000.0;
		plots <- plots where not dead(each);
		productivity_level <- (plots sum_of each.current_productivity) / length(plots) / 100.0;
	}
	
	action choice_on_waste_collection_team {
		
	}
	
	action trimestrial_collective_action {
		if budget >= token_trimestrial_collective_action {
			ask canals {
				solid_waste_level <- solid_waste_level * (1 - impact_trimestrial_collective_action);
			}
			budget <- budget - token_trimestrial_collective_action;
		}
		
	}
	
	action drain_dredge {
		if budget >= token_drain_dredge {
			is_drained <- true;
			ask canals {
				solid_waste_level <- solid_waste_level * (1 - impact_drain_dredge_waste);
				
			}
			budget <- budget - token_drain_dredge;
		}
	}
	
	action install_filter_for_homes {
		
	}
	
	action sensibilization {
		
	}
	
	action pesticide_reducing {
		
	}
	
	action implement_fallow {
		
	}
	
	action support_manure_buying {
		
	}
	
	action farmer_training {
		
	}
	
	action support_digital_tools {
		
	}
	action end_of_turn {
		bool  is_ok <- user_confirm("End of turn","PLAYER " + (index_player + 1) +", do you confirm that you want to end the turn?");
		if is_ok {
			
			index_player <- index_player + 1;
			if index_player < length(village) {
				
				do tell("PLAYER " + (index_player + 1) + " TURN");
			}
		}
	}
	
	aspect default {
		if (stage = PLAYER_TURN) {
			if (index_player = int(self)) {
				draw shape color: color;
			}
		} else {
			
			draw shape.contour + 20.0 color: color;
		}
	}
}

species plot {
	village the_village;
	float base_productivity <- field_initial_productivity min: 0.0;
	float current_productivity min: 0.0;
	float pratice_water_pollution_level;
	float part_to_canal_of_pollution;
	canal closest_canal;
	farmer the_farmer;
	list<cell> my_cells;
	communal_landfill the_communal_landfill;
	local_landfill the_local_landfill;
	bool impacted_by_canal <- false;
	
	action pollution_due_to_practice { 
		if pratice_water_pollution_level > 0 {
			float to_the_canal <- pratice_water_pollution_level * part_to_canal_of_pollution;
			float to_the_ground <- pratice_water_pollution_level - to_the_canal;
			if to_the_canal > 0 {
				closest_canal.water_waste_level <- closest_canal.water_waste_level + to_the_canal;
			}
			if to_the_ground > 0 {
				ask my_cells {
					water_waste_level <- water_waste_level + to_the_ground  ;
				}
			}
		}
	}
	
	action compute_productivity {
		current_productivity <- base_productivity;
		if the_village.is_drained {
			current_productivity <- current_productivity * (1 + impact_drain_dredge_agriculture);
		}
		if (the_local_landfill != nil) {
			current_productivity <- current_productivity - the_local_landfill.waste_quantity * local_landfill_waste_pollution_impact_rate;
		}
		if (the_communal_landfill != nil) {
			current_productivity <- current_productivity - the_communal_landfill.waste_quantity * communal_landfill_waste_pollution_impact_rate;
		}
		float solid_ground_pollution <- my_cells sum_of each.solid_waste_level;
		if (solid_ground_pollution > 0) {
			current_productivity <- current_productivity - solid_ground_pollution * ground_solid_waste_pollution_impact_rate;
		}
		float water_ground_pollution <- my_cells sum_of each.water_waste_level;
		if (solid_ground_pollution > 0) {
			current_productivity <- current_productivity - water_ground_pollution * ground_water_waste_pollution_impact_rate;
		}
		if impacted_by_canal {
			current_productivity <- current_productivity - closest_canal.solid_waste_level * canal_solid_waste_pollution_impact_rate; 
			current_productivity <- current_productivity - closest_canal.water_waste_level * canal_water_waste_pollution_impact_rate; 
		}
	}
	
	aspect default {
		draw shape color: #green border: #black;
	}
}

species urban_area {
	float population;
	list<village> my_villages;
}
species house {
	aspect default {
		draw shape color: #gray border: #black;
	}
}
species canal {
	float solid_waste_level min: 0.0;
	float water_waste_level min: 0.0;
	float solid_waste_level_tmp;
	float water_waste_level_tmp;
	list<canal> downtream_canals;
	
	
	action init_flow {
		solid_waste_level_tmp <- 0.0;
		water_waste_level_tmp <- 0.0;
	}
	action flow {
		
		float to_diffuse_solid <-  solid_waste_level / shape.perimeter  * rate_diffusion_solid_waste  ; 
		float to_diffuse_water <-  water_waste_level / shape.perimeter  * rate_diffusion_liquid_waste ; 
		
		int nb <- length(downtream_canals);
		if nb > 0 {
			ask downtream_canals {
				solid_waste_level_tmp <- solid_waste_level_tmp + to_diffuse_solid/ nb;
				water_waste_level_tmp <- water_waste_level_tmp +to_diffuse_water  / nb;
			}
		}
		solid_waste_level_tmp <- solid_waste_level_tmp - to_diffuse_solid ;
		water_waste_level_tmp <-  water_waste_level_tmp - to_diffuse_water;
	}
	action update_waste {
		solid_waste_level <- solid_waste_level + solid_waste_level_tmp;
		water_waste_level <- water_waste_level + water_waste_level_tmp ;
	}
	aspect default {
		draw shape + 10.0 color: blend(#red,#blue,(solid_waste_level+water_waste_level)/shape.perimeter / coeff_visu_canal);
		draw "" + int(self) + " -> " + (downtream_canals collect int(each)) color: #black;
	}
}

species commune {
	rgb color <- #pink;
	aspect default {
		draw shape color: color;
	}
}

species local_landfill {
	village my_village;
	float waste_quantity;
	
	aspect default {
		draw circle(50) depth: waste_quantity / 10.0 border: #blue color: #red;
	}
		
	action transfert_waste_to_communal_level {
		if waste_quantity > 0 {
			float to_transfert <- min(quantity_from_local_to_communal_landfill, waste_quantity);
			the_communal_landfill.waste_quantity <- the_communal_landfill.waste_quantity + to_transfert;
			waste_quantity <- waste_quantity - to_transfert;
		}
		
	}
}
/*species treatment_factory {
	float capacity_per_day;
	
	reflex treatment when: stage = COMPUTE_INDICATORS {
		float treated <- 0.0;
		ask dumpyard {
			float max_treated <- min(waste_quantity, myself.capacity_per_day);
			waste_quantity <- waste_quantity - max_treated;
		}
	}
	aspect default {
		draw circle(capacity_per_day * 50.0) border: #black color: #gold;
	}
}*/

species communal_landfill {
	float waste_quantity min: 0.0;
	
	aspect default {
		draw circle(100) depth: waste_quantity / 10.0 border: #blue color: #red;
	}
	
	action manage_waste {
		if waste_quantity > 0 {
			waste_quantity <- waste_quantity - quantity_communal_landfill_to_treatment;
		}
		
	}
}

species farmer parent: inhabitant {
	rgb color <- #yellow;
	float max_agricultural_waste_production <- rnd(1.0, 3.0);
	float solid_waste_day <- nb_people * solid_waste_year_farmers / 365;
	float water_waste_day <- nb_people * water_waste_year_farmers / 365;
	float part_solid_waste_canal <- part_solid_waste_canal_farmers;
	float part_water_waste_canal <- part_water_waste_canal_farmers;
}
species inhabitant {
	rgb color <- #red;
	cell my_house;
	canal closest_canal;
	float nb_people <- 1.0;
	float solid_waste_day <- nb_people * solid_waste_year_inhabitants / 365;
	float water_waste_day <- nb_people * water_waste_year_inhabitants / 365;
	float part_solid_waste_canal <- part_solid_waste_canal_inhabitants;
	float part_water_waste_canal <- part_water_waste_canal_inhabitants;
	list<cell> my_cells;
	aspect default {
		draw circle(10.0) color: color;
	}
	
	action domestic_waste_production {
		if solid_waste_day > 0 {
			float to_the_canal <- solid_waste_day * part_solid_waste_canal;
			float to_the_ground <- solid_waste_day - to_the_canal;
			if to_the_canal > 0 {
				closest_canal.solid_waste_level <- closest_canal.solid_waste_level + to_the_canal;
			}
			if to_the_ground > 0 {
				ask one_of(my_cells) {
					solid_waste_level <- solid_waste_level + to_the_ground ;
				}
			}
		}
		if water_waste_day > 0 {
			float to_the_canal <- water_waste_day * part_water_waste_canal;
			float to_the_ground <- water_waste_day - to_the_canal;
			if to_the_canal > 0 {
				closest_canal.water_waste_level <- closest_canal.water_waste_level + to_the_canal;
			}
			if to_the_ground > 0 {
				ask one_of(my_cells) {
					water_waste_level <- water_waste_level + to_the_ground ;
				}
			}
			
		}	
	}
}

species collection_team {
	rgb color <- #gold;
	int nb_collection_week <-collect_per_week_weak;
	float collection_capacity <- collection_team_collection_capacity_day;
	village my_village;
	
	
	action collect_waste {
		float waste_collected <- 0.0;
		loop while: waste_collected < collection_capacity  {
			list<cell> cells_to_clean <-  my_village.cells where (each.solid_waste_level > 0);
			if  empty(cells_to_clean) {
				break;
			}
			else {
				cell the_cell <- cells_to_clean with_max_of (each.solid_waste_level);
				ask the_cell{
					float w <- min(myself.collection_capacity - waste_collected, solid_waste_level);
					waste_collected <- waste_collected + w;
					solid_waste_level <- solid_waste_level  - w;
				}
			}
		}
		ask my_village.my_local_landfill {
			waste_quantity <- waste_quantity + waste_collected;
		}
	}
}

experiment base_display virtual: true {
	output {
		display map type: opengl  background: #black axes: false refresh: stage = COMPUTE_INDICATORS{
		/*	graphics "legend" {
				draw (stage +" " + (stage = PLAYER_TURN ? ("Player " + (index_player + 1) + " - Global budget: " + global_budget) : ""))  font: font("Helvetica", 50 , #bold) at: {world.location.x, 10} anchor:#center color: #white;
			} */
			chart "Indicators Territory 1" type: radar background: #black size: {0.4, 0.4} position: {-0.3, 0.0}  x_serie_labels: ["solid waste", "water waste", "productivity"] color: #white series_label_position: xaxis{
				data "Pollution level" value: [village[0].solid_pollution_level,village[0].water_pollution_level,village[0].productivity_level] color:village[0].color;
				
			}
			
			chart "Indicators Territory 2" type: radar background: #black size: {0.4, 0.4} position: {-0.3, 0.7} x_serie_labels: ["solid waste", "water waste", "productivity"] color: #white series_label_position: xaxis{
				data "Pollution level" value: [village[1].solid_pollution_level,village[1].water_pollution_level,village[1].productivity_level] color:village[1].color;
					
			}
			chart "Indicators Territory 3" type: radar background: #black size: {0.4, 0.4} position: {1.0, 0.0} x_serie_labels:  ["solid waste", "water waste", "productivity"] color: #white series_label_position: xaxis{
				data "Pollution level" value: [village[2].solid_pollution_level,village[2].water_pollution_level,village[2].productivity_level] color:village[2].color;
				
			}
			chart "Indicators Territory 4" type: radar background: #black size: {0.4, 0.4} position: {1.0, 0.7} x_serie_labels:  ["solid waste", "water waste", "productivity"] color: #white series_label_position: xaxis{
				data "Pollution level" value: [village[3].solid_pollution_level,village[3].water_pollution_level,village[3].productivity_level] color:village[3].color;
				
			}
			
			species commune;
			species house;
			species plot;
			species canal;
			species cell transparency: 0.5 ;
			species inhabitant;
			species farmer;
			species collection_team;
			species local_landfill;
			species communal_landfill;
			species village transparency: 0.5 ;
			
		
			
			//event mouse_down action: create_bin; 
		}
		display "global indicators" background: #black{
			chart "Waste pollution " size:{1.0, 0.3} background: #black color: #white{
				data "Water waste pollution" value: canal sum_of each.water_waste_level + cell sum_of each.water_waste_level  color: #red marker: false;
			}
			chart "Waste pollution " position:{0, 1/3} size:{1.0, 1/3} background: #black color: #white{
				data "Solid waste pollution" value: canal sum_of each.solid_waste_level + cell sum_of each.solid_waste_level  color: #red marker: false;
			}
			
			/*chart "VietGap " position:{0, 2/3} size:{1.0, 1/3} background: #black{
				data "?????" value: ???  color: #red marker: false;
			}*/
		}
	}
}

experiment simulation_without_players parent: base_display type: gui {
	action _init_ {
		create simulation with:(without_player:true);
	}
}

experiment the_serious_game parent: base_display type: gui {
	
	output {
		display action_buton background:#black name:"Tools panel"  	{
			
			species button aspect:normal ;
			event mouse_down action:activate_act;    
		}
		
	}
}
