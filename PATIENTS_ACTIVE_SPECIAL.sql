   SELECT coorte12meses_final.patient_id FROM
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
	WHERE (data_estado IS NULL or (data_estado is NOT NULL AND  data_fila > data_estado)) AND date_add(next_drug_pickup_date, interval 28 day) >= :endDate