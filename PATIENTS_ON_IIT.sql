   SELECT coorte12meses_final.patient_id, floor(datediff( :endDate,patient_info.birthdate)/365) age, patient_info.gender as sex, level_of_education.level_of_education, reason_of_visit.reason_of_visit, DATE(last_appointment.last_appointment_date) as last_appointment_date, 
   first_who_stage.first_who_stage, last_who_stage.last_who_stage, first_viral_load.first_viral_load, last_viral_load.last_viral_load, treatment_adhesion.treatment_adhesion, hiv_disclose.hiv_disclose, phycological_factors.phycological_factors, DATE(data_inicio) as art_start_date,  
   first_art_regimen.first_art_regimen, last_art_regimen.last_art_regimen, art_line.art_line, art_line_change.art_line_change, art_line_change_reason.art_line_change_reason, art_status_change.art_status_change, side_effects.side_effects, type_of_dispensation.type_of_dispensation,method_of_dispensation.method_of_dispensation, next_drug_pickup_date FROM 
   (
		SELECT inicio_fila_seg_prox.*, GREATEST(COALESCE(data_proximo_lev,data_recepcao_levantou30), COALESCE(data_recepcao_levantou30,data_proximo_lev)) next_drug_pickup_date FROM 
		(
			SELECT inicio_fila_seg.*, MAX(obs_fila.value_datetime) data_proximo_lev, date_add(data_recepcao_levantou, interval 30 day) data_recepcao_levantou30 FROM 
			(
				SELECT inicio.*, saida.data_estado, max_fila.data_fila, max_recepcao.data_recepcao_levantou FROM 
				(
					SELECT patient_id,data_inicio FROM 
					(
						SELECT patient_id, data_inicio FROM 
						(
							SELECT patient_id, MIN(data_inicio) data_inicio FROM 
							(
								SELECT p.patient_id, MIN(e.encounter_datetime) data_inicio FROM patient p 
									INNER JOIN encounter e ON p.patient_id=e.patient_id 
									INNER JOIN obs o ON o.encounter_id=e.encounter_id 
										WHERE e.voided=0 AND o.voided=0 AND p.voided=0 AND e.encounter_type in (18,6,9) 
											AND o.concept_id=1255 AND o.value_coded=1256 AND e.encounter_datetime<= :endDate AND e.location_id= :location
												GROUP BY p.patient_id 
								UNION
								
								SELECT p.patient_id, MIN(value_datetime) data_inicio FROM patient p 
									INNER JOIN encounter e ON p.patient_id=e.patient_id 
									INNER JOIN obs o ON e.encounter_id=o.encounter_id 
										WHERE p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type in (18,6,9,53) 
											AND o.concept_id=1190 AND o.value_datetime is NOT NULL AND o.value_datetime<= :endDate AND e.location_id= :location
												GROUP BY p.patient_id 
								
								UNION
					
								SELECT pg.patient_id, MIN(date_enrolled) data_inicio FROM patient p 
									INNER JOIN patient_program pg ON p.patient_id=pg.patient_id 
										WHERE pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<= :endDate AND location_id= :location
											GROUP BY pg.patient_id 
								
								UNION
			
								SELECT e.patient_id, MIN(e.encounter_datetime) as data_inicio FROM patient p 
									INNER JOIN encounter e ON p.patient_id=e.patient_id 
										WHERE p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<= :endDate AND e.location_id= :location
											GROUP BY p.patient_id 
								
								UNION
					
								SELECT p.patient_id, MIN(value_datetime) data_inicio FROM patient p 
									INNER JOIN encounter e ON p.patient_id=e.patient_id 
									INNER JOIN obs o ON e.encounter_id=o.encounter_id 
										WHERE p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 
											AND o.concept_id=23866 AND o.value_datetime is NOT NULL AND o.value_datetime<= :endDate AND e.location_id= :location
												GROUP BY p.patient_id
												
							)art_start GROUP BY patient_id 
						) tx_new WHERE data_inicio <=  :endDate AND data_inicio < '2023-12-21'
						
						UNION

						SELECT tx_new.patient_id, tx_new.data_inicio FROM 
						(
							SELECT tx_new.patient_id, tx_new.data_inicio FROM
							( 
								SELECT patient_id, data_inicio FROM 
								(
									SELECT patient_id, MIN(data_inicio) data_inicio FROM 
									(
										SELECT e.patient_id, MIN(e.encounter_datetime) as data_inicio FROM patient p 
											INNER JOIN encounter e ON p.patient_id=e.patient_id 
												WHERE p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<= :endDate AND e.location_id= :location
													GROUP BY p.patient_id 

										UNION
							
										SELECT p.patient_id, MIN(value_datetime) data_inicio FROM patient p 
											INNER JOIN encounter e ON p.patient_id=e.patient_id 
											INNER JOIN obs o ON e.encounter_id=o.encounter_id 
												WHERE p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 
													AND o.concept_id=23866 AND o.value_datetime is NOT NULL AND o.value_datetime<= :endDate AND e.location_id= :location
														GROUP BY p.patient_id
									) art_start GROUP BY patient_id 
								) tx_new WHERE data_inicio <=  :endDate AND data_inicio >= '2023-12-21'
							) tx_new
							
							LEFT JOIN
							(
								SELECT patient_id FROM 
								(
									SELECT patient_id, MIN(data_inicio) data_inicio FROM 
									(
										SELECT p.patient_id, MIN(e.encounter_datetime) data_inicio FROM patient p 
											INNER JOIN encounter e ON p.patient_id=e.patient_id 
											INNER JOIN obs o ON o.encounter_id=e.encounter_id 
												WHERE e.voided=0 AND o.voided=0 AND p.voided=0 AND e.encounter_type in (18,6,9) 
													AND o.concept_id=1255 AND o.value_coded=1256 AND e.encounter_datetime<= :endDate AND e.location_id= :location
														GROUP BY p.patient_id 
										
										UNION
										
										SELECT p.patient_id, MIN(value_datetime) data_inicio FROM patient p 
											INNER JOIN encounter e ON p.patient_id=e.patient_id 
											INNER JOIN obs o ON e.encounter_id=o.encounter_id 
												WHERE p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type in (18,6,9,53) 
													AND o.concept_id=1190 AND o.value_datetime is NOT NULL AND o.value_datetime<= :endDate AND e.location_id= :location
														GROUP BY p.patient_id 
										
										UNION
							
										SELECT pg.patient_id, MIN(date_enrolled) data_inicio FROM patient p 
											INNER JOIN patient_program pg ON p.patient_id=pg.patient_id 
												WHERE pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<= :endDate AND location_id= :location
													GROUP BY pg.patient_id 
									)art_start GROUP BY patient_id 
								) tx_new WHERE data_inicio < '2023-12-21'
							) tx_new_period_anterior ON tx_new.patient_id = tx_new_period_anterior.patient_id WHERE tx_new_period_anterior.patient_id IS NULL
						) tx_new
					) inicio
				)inicio                                                                                                                                    
              LEFT JOIN
			  (
				SELECT patient_id,MAX(data_estado) data_estado FROM
				(
					SELECT distinct max_estado.patient_id, max_estado.data_estado FROM 
					(
						SELECT  pg.patient_id, MAX(ps.start_date) data_estado FROM patient p INNER JOIN patient_program pg ON p.patient_id = pg.patient_id                                                               
                                     INNER JOIN patient_state ps ON pg.patient_program_id = ps.patient_program_id 
									 	WHERE pg.voided=0 AND ps.voided=0 AND p.voided=0 AND pg.program_id = 2 AND ps.start_date<=  :endDate AND pg.location_id = :location 
											GROUP BY pg.patient_id                                           
                    ) max_estado                                                                                                                        
					
					INNER JOIN patient_program pp ON pp.patient_id = max_estado.patient_id                                                          
					INNER JOIN patient_state ps ON ps.patient_program_id = pp.patient_program_id AND ps.start_date = max_estado.data_estado         
						WHERE pp.program_id = 2 AND ps.state = 8 AND pp.voided = 0 AND ps.voided = 0 AND pp.location_id =  :location                         
					
					UNION
					
					SELECT dead_state.patient_id, dead_state.data_estado FROM 
					(
						SELECT patient_id,MAX(data_estado) data_estado FROM
						(
							SELECT distinct max_estado.patient_id, max_estado.data_estado FROM 
							(                                                                
								SELECT  pg.patient_id, MAX(ps.start_date) data_estado FROM patient p                                                                                                               
									INNER JOIN patient_program pg ON p.patient_id = pg.patient_id                                                               
									INNER JOIN patient_state ps ON pg.patient_program_id = ps.patient_program_id                                                
										WHERE pg.voided=0 AND ps.voided=0 AND p.voided=0 AND pg.program_id = 2                                        
											AND ps.start_date<=  :endDate AND pg.location_id = :location 
												GROUP BY pg.patient_id                                           
							) max_estado                                                                                                                        
												
							INNER JOIN patient_program pp ON pp.patient_id = max_estado.patient_id                                                          
							INNER JOIN patient_state ps ON ps.patient_program_id = pp.patient_program_id AND ps.start_date = max_estado.data_estado
							WHERE pp.program_id = 2 AND ps.state = 10 AND pp.voided = 0 AND ps.voided = 0 AND pp.location_id = :location 
							
							UNION

							SELECT  p.patient_id, MAX(o.obs_datetime) data_estado FROM patient p                                                                                                                   
								INNER JOIN encounter e ON p.patient_id=e.patient_id                                                                         
								INNER JOIN obs  o ON e.encounter_id=o.encounter_id                                                                          
									WHERE e.voided=0 AND o.voided=0 AND p.voided=0                                                                
										AND e.encounter_type in (53,6) AND o.concept_id in (6272,6273) AND o.value_coded = 1366                         
											AND o.obs_datetime<= :endDate AND e.location_id= :location                                                                       
												GROUP BY p.patient_id                                                                                                               
							
							UNION                                                                                                                              
							
							SELECT person_id as patient_id,death_date as data_estado FROM person                                                                                                                         
								WHERE dead=1 AND voided = 0 AND death_date is NOT NULL AND death_date<= :endDate 
											
							
							UNION
							
							SELECT  p.patient_id, MAX(obsObito.obs_datetime) data_estado FROM patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id
								INNER JOIN obs obsObito ON e.encounter_id=obsObito.encounter_id 
									WHERE e.voided=0 AND p.voided=0 AND obsObito.voided=0 AND e.encounter_type in (21,36,37) 
									AND  e.encounter_datetime<= :endDate AND  e.location_id= :location                         
									AND obsObito.concept_id in (2031,23944,23945) AND obsObito.value_coded=1366                                                     
											GROUP BY p.patient_id                                                                                                               
						) dead_state GROUP BY dead_state.patient_id 
					) dead_state 
					
					INNER JOIN
					
					(
						SELECT fila_seguimento.patient_id,MAX(fila_seguimento.data_encountro) data_encountro FROM 
						(
							SELECT p.patient_id,MAX(encounter_datetime) data_encountro FROM patient p 
								INNER JOIN encounter e ON e.patient_id=p.patient_id                                                                                         
									WHERE p.voided=0 AND e.voided=0 AND e.encounter_type=18                                                                      
										AND e.location_id= :location AND e.encounter_datetime<= :endDate                                                                                  
											GROUP BY p.patient_id  
								UNION
									
								SELECT  p.patient_id,MAX(encounter_datetime) data_encountro FROM patient p                                                                                                                                   
									INNER JOIN encounter e ON e.patient_id=p.patient_id 
										WHERE p.voided=0 AND e.voided=0 AND e.encounter_type in (6,9)                                                                
											AND e.location_id= :location AND e.encounter_datetime<= :endDate                                                                                  
												GROUP BY p.patient_id

						) fila_seguimento GROUP BY fila_seguimento.patient_id  
					) fila_seguimento ON dead_state.patient_id = fila_seguimento.patient_id
								WHERE fila_seguimento.data_encountro IS NULL or fila_seguimento.data_encountro <= dead_state.data_estado
							 
					UNION
					
					SELECT p.patient_id, MAX(o.obs_datetime) data_estado FROM patient p                                                                                                                   
							INNER JOIN encounter e ON p.patient_id=e.patient_id                                                                         
							INNER JOIN obs  o ON e.encounter_id=o.encounter_id                                                                          
								WHERE e.voided=0 AND o.voided=0 AND p.voided=0 AND e.encounter_type in (53,6) 
								AND o.concept_id in (6272,6273) AND o.value_coded = 1709 AND o.obs_datetime<= :endDate AND e.location_id= :location                                                                       
									GROUP BY p.patient_id                                                                                                               
					
					UNION
					
					SELECT saidas_por_transferencia.patient_id, data_estado FROM
					(
						SELECT saidas_por_transferencia.patient_id, MAX(data_estado) data_estado FROM
						(
							SELECT distinct max_estado.patient_id, max_estado.data_estado FROM 
							(
								SELECT pg.patient_id, MAX(ps.start_date) data_estado FROM patient p                                                                                                               
									INNER JOIN patient_program pg ON p.patient_id = pg.patient_id                                                               
									INNER JOIN patient_state ps ON pg.patient_program_id = ps.patient_program_id                                                
										WHERE pg.voided=0 AND ps.voided=0 AND p.voided=0 AND pg.program_id = 2                                        
											AND ps.start_date<=  :endDate AND pg.location_id = :location
												GROUP BY pg.patient_id                                           
							) max_estado
							INNER JOIN patient_program pp ON pp.patient_id = max_estado.patient_id
							INNER JOIN patient_state ps ON ps.patient_program_id = pp.patient_program_id AND ps.start_date = max_estado.data_estado         
								WHERE pp.program_id = 2 AND ps.state = 7 AND pp.voided = 0 AND ps.voided = 0 AND pp.location_id =  :location                
								
							UNION
							
							SELECT p.patient_id,MAX(o.obs_datetime) data_estado FROM patient p                                                                                                                   
								INNER JOIN encounter e ON p.patient_id=e.patient_id                                                                         
								INNER JOIN obs o ON e.encounter_id=o.encounter_id                                                                          
									WHERE e.voided=0 AND o.voided=0 AND p.voided=0                                                                
										AND e.encounter_type in (53,6) AND o.concept_id in (6272,6273) AND o.value_coded = 1706                         
										AND o.obs_datetime<= :endDate AND e.location_id= :location                                                                       
											GROUP BY p.patient_id                                                                                                               
									
							UNION                                                                                                                              
									
							SELECT ultimaBusca.patient_id, ultimaBusca.data_estado FROM 
							(
								SELECT p.patient_id,MAX(e.encounter_datetime) data_estado FROM patient p 
									INNER JOIN encounter e ON p.patient_id=e.patient_id
									INNER JOIN obs o ON o.encounter_id=e.encounter_id                                                                       
										WHERE e.voided=0 AND p.voided=0 AND e.encounter_datetime<=  :endDate                                       
											AND e.encounter_type = 21 AND  e.location_id=  :location                                                                
												GROUP BY p.patient_id                                                                                                   
							) ultimaBusca                                                                                                                   
							INNER JOIN encounter e ON e.patient_id = ultimaBusca.patient_id                                                             
							INNER JOIN obs o ON o.encounter_id = e.encounter_id                                                                         
								WHERE e.encounter_type = 21 AND o.voided=0 AND o.concept_id=2016 AND o.value_coded in (1706,23863) AND ultimaBusca.data_estado = e.encounter_datetime AND e.location_id =  :location
						) saidas_por_transferencia GROUP BY patient_id 
                    ) saidas_por_transferencia
					
					LEFT JOIN
					(  
						SELECT patient_id, MAX(data_ultimo_levantamento) data_ultimo_levantamento FROM
						(
							SELECT p.patient_id, date_add(MAX(o.value_datetime), interval 1 day) data_ultimo_levantamento FROM patient p                                                                                                                                   
								INNER JOIN encounter e ON e.patient_id= p.patient_id 
								INNER JOIN obs o ON o.encounter_id = e.encounter_id                                                                                        
									WHERE p.voided= 0 AND e.voided=0 AND o.voided = 0 AND e.encounter_type=18 AND o.concept_id = 5096                                                                  
										AND e.location_id= :location AND e.encounter_datetime <=  :endDate                                                                               
											GROUP BY p.patient_id 
					
							UNION
					
							SELECT p.patient_id, date_add(MAX(value_datetime), interval 31 day) data_ultimo_levantamento FROM patient p                                                                                                                                   
								INNER JOIN encounter e ON p.patient_id=e.patient_id                                                                                         
								INNER JOIN obs o ON e.encounter_id=o.encounter_id                                                                                           
									WHERE p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52                                                       
										AND o.concept_id=23866 AND o.value_datetime is NOT NULL AND e.location_id= :location AND o.value_datetime <=  :endDate                                                                                        
											GROUP BY p.patient_id
						) ultimo_levantamento GROUP BY patient_id
					) ultimo_levantamento ON saidas_por_transferencia.patient_id = ultimo_levantamento.patient_id 
					WHERE ultimo_levantamento.data_ultimo_levantamento <=  :endDate																																					
				) allSaida GROUP BY patient_id 
            ) saida ON inicio.patient_id = saida.patient_id
			
			LEFT JOIN
			(
				SELECT p.patient_id,MAX(encounter_datetime) data_fila FROM patient p                                                                                                                                   
                     INNER JOIN encounter e ON e.patient_id=p.patient_id                                                                                         
             			WHERE p.voided=0 AND e.voided=0 AND e.encounter_type=18 AND e.location_id= :location AND e.encounter_datetime<= :endDate                                                                                  
             				GROUP BY p.patient_id                                                                                                                               
            ) max_fila ON inicio.patient_id=max_fila.patient_id  
            
			LEFT JOIN                                                                                                                                          
            (
				SELECT  p.patient_id,MAX(value_datetime) data_recepcao_levantou FROM patient p                                                                                                                                   
                     INNER JOIN encounter e ON p.patient_id=e.patient_id                                                                                         
                     INNER JOIN obs o ON e.encounter_id=o.encounter_id                                                                                           
             			WHERE p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type=52 AND o.concept_id=23866 AND o.value_datetime is NOT NULL 
						AND o.value_datetime<= :endDate AND e.location_id= :location                                                                                     
             				GROUP BY p.patient_id                                                                                                                               
            ) max_recepcao ON inicio.patient_id=max_recepcao.patient_id GROUP BY inicio.patient_id                                                                                                                         
		) inicio_fila_seg
		
		LEFT JOIN encounter ultimo_fila_data_criacao ON ultimo_fila_data_criacao.patient_id=inicio_fila_seg.patient_id                                                                                      
			AND ultimo_fila_data_criacao.voided=0                                     
			AND ultimo_fila_data_criacao.encounter_type = 18  
			AND ultimo_fila_data_criacao.encounter_datetime = inicio_fila_seg.data_fila                                                                                            
			AND ultimo_fila_data_criacao.location_id= :location                    
        
		LEFT JOIN obs obs_fila ON obs_fila.person_id=inicio_fila_seg.patient_id                                                                                      
               	AND obs_fila.voided=0                                                                                                                             
              	AND (obs_fila.obs_datetime=inicio_fila_seg.data_fila  or (ultimo_fila_data_criacao.date_created = obs_fila.date_created AND ultimo_fila_data_criacao.encounter_id = obs_fila.encounter_id ))                                                                                                       
              	AND obs_fila.concept_id=5096                                                                                                                       
              	AND obs_fila.location_id= :location                                                                                                                
        		GROUP BY inicio_fila_seg.patient_id
    ) inicio_fila_seg_prox GROUP BY patient_id

) coorte12meses_final
INNER JOIN 
(
	SELECT pe.person_id, pe.birthdate, pe.gender FROM person pe
		WHERE pe.voided = 0 AND pe.dead = 0 AND pe.birthdate IS NOT NULL
			GROUP BY pe.person_id
)patient_info ON patient_info.person_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, level_of_education FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 53
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		SELECT o.person_id as patient_id, o.value_coded as level_of_education, o.obs_datetime as obs_date FROM obs o
				WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 1443
	)education ON last_enconunter.patient_id = education.patient_id AND last_enconunter.enconunter_date = education.obs_date
)level_of_education ON level_of_education.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, reason_of_visit FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 35
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		SELECT o.person_id as patient_id, o.value_coded as reason_of_visit, o.obs_datetime as obs_date FROM obs o
			WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 6315
	)visit ON last_enconunter.patient_id = visit.patient_id AND last_enconunter.enconunter_date = visit.obs_date
)reason_of_visit ON reason_of_visit.patient_id = coorte12meses_final.patient_id
LEFT JOIN
(
	SELECT p.patient_id, MAX(e.encounter_datetime) last_appointment_date FROM patient p
		INNER JOIN encounter e ON e.patient_id = p.patient_id
			WHERE p.voided = 0 AND e.encounter_type IN (6,9)
				AND e.voided = 0 AND e.encounter_datetime <= :endDate
				AND e.location_id = :location
					GROUP BY p.patient_id	

)last_appointment ON last_appointment.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, first_who_stage FROM (
		SELECT p.patient_id, MIN(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type IN (6,53)
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		SELECT o.person_id as patient_id, o.value_coded as first_who_stage, o.obs_datetime as obs_date FROM obs o
			WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 5356
	)who_stage ON last_enconunter.patient_id = who_stage.patient_id AND last_enconunter.enconunter_date = who_stage.obs_date
)first_who_stage ON first_who_stage.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, last_who_stage FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type IN (6,53)
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		SELECT o.person_id as patient_id, o.value_coded as last_who_stage, o.obs_datetime as obs_date FROM obs o
			WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 5356
	)who_stage ON last_enconunter.patient_id = who_stage.patient_id AND last_enconunter.enconunter_date = who_stage.obs_date
)last_who_stage ON last_who_stage.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, first_viral_load FROM (
		SELECT p.patient_id, MIN(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type IN (6,13,53)
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		SELECT o.person_id as patient_id, o.value_numeric as first_viral_load, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.concept_id = 856
	)viral_load ON last_enconunter.patient_id = viral_load.patient_id AND last_enconunter.enconunter_date = viral_load.obs_date
)first_viral_load ON first_viral_load.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, last_viral_load FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type IN (6,13,53)
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		SELECT o.person_id as patient_id, o.value_numeric as last_viral_load, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.concept_id = 856
	)viral_load ON last_enconunter.patient_id = viral_load.patient_id AND last_enconunter.enconunter_date = viral_load.obs_date
)last_viral_load ON last_viral_load.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, treatment_adhesion FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type IN (6,35)
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as treatment_adhesion, o.obs_datetime as obs_date FROM obs o
            WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 6223
	)adhesion ON last_enconunter.patient_id = adhesion.patient_id AND last_enconunter.enconunter_date = adhesion.obs_date
)treatment_adhesion ON treatment_adhesion.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, hiv_disclose FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 35
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as hiv_disclose, o.obs_datetime as obs_date FROM obs o
            LEFT JOIN concept_name cn ON cn.concept_id = o.value_coded
                WHERE o.voided = 0 AND cn.voided = 0 AND cn.locale = 'en' AND cn.locale_preferred = 1
                    AND o.obs_datetime <= :endDate AND o.concept_id = 1048
	)disclose ON last_enconunter.patient_id = disclose.patient_id AND last_enconunter.enconunter_date = disclose.obs_date
)hiv_disclose ON hiv_disclose.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, phycological_factors FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 35
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as phycological_factors, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 6193
	)phycological_factors ON last_enconunter.patient_id = phycological_factors.patient_id AND last_enconunter.enconunter_date = phycological_factors.obs_date
)phycological_factors ON phycological_factors.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, first_art_regimen FROM (
		SELECT p.patient_id, MIN(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as first_art_regimen, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 1087
	)art_regimen ON last_enconunter.patient_id = art_regimen.patient_id AND last_enconunter.enconunter_date = art_regimen.obs_date
)first_art_regimen ON first_art_regimen.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, last_art_regimen FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as last_art_regimen, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 1087
	)art_regimen ON last_enconunter.patient_id = art_regimen.patient_id AND last_enconunter.enconunter_date = art_regimen.obs_date
)last_art_regimen ON last_art_regimen.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, art_line FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as art_line, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 21151
	)art_line ON last_enconunter.patient_id = art_line.patient_id AND last_enconunter.enconunter_date = art_line.obs_date
)art_line ON art_line.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, art_line_change FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as art_line_change, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 23742
	)art_line_change ON last_enconunter.patient_id = art_line_change.patient_id AND last_enconunter.enconunter_date = art_line_change.obs_date
)art_line_change ON art_line_change.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, art_line_change_reason FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as art_line_change_reason, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 1792
	)art_line_change_reason ON last_enconunter.patient_id = art_line_change_reason.patient_id AND last_enconunter.enconunter_date = art_line_change_reason.obs_date
)art_line_change_reason ON art_line_change_reason.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, art_status_change FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type IN (6,53)
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as art_status_change, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id IN (6272,6273)
	)art_status_change ON last_enconunter.patient_id = art_status_change.patient_id AND last_enconunter.enconunter_date = art_status_change.obs_date
)art_status_change ON art_status_change.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, side_effects FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as side_effects, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 2015
	)side_effects ON last_enconunter.patient_id = side_effects.patient_id AND last_enconunter.enconunter_date = side_effects.obs_date
)side_effects ON side_effects.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, type_of_dispensation FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 6
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as type_of_dispensation, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id =  23739
	)type_of_dispensation ON last_enconunter.patient_id = type_of_dispensation.patient_id AND last_enconunter.enconunter_date = type_of_dispensation.obs_date
)type_of_dispensation ON type_of_dispensation.patient_id = coorte12meses_final.patient_id

LEFT JOIN
(
	SELECT last_enconunter.patient_id, method_of_dispensation FROM (
		SELECT p.patient_id, MAX(e.encounter_datetime) enconunter_date FROM patient p
			INNER JOIN encounter e ON e.patient_id = p.patient_id
				WHERE p.voided = 0 AND e.encounter_type = 18
					AND e.voided = 0 AND e.encounter_datetime <= :endDate
					AND e.location_id = :location
						GROUP BY p.patient_id
	)last_enconunter
	INNER JOIN (
		 SELECT o.person_id as patient_id, o.value_coded as method_of_dispensation, o.obs_datetime as obs_date FROM obs o
                WHERE o.voided = 0 AND o.obs_datetime <= :endDate AND o.concept_id = 165174	
	)method_of_dispensation ON last_enconunter.patient_id = method_of_dispensation.patient_id AND last_enconunter.enconunter_date = method_of_dispensation.obs_date
)method_of_dispensation ON method_of_dispensation.patient_id = coorte12meses_final.patient_id

	WHERE (data_estado IS NULL or (data_estado is NOT NULL AND  data_fila > data_estado)) AND date_add(next_drug_pickup_date, interval 28 day) < :endDate
		GROUP BY coorte12meses_final.patient_id