SELECT e.patient_id, e.encounter_datetime as clinical_contact_date, o.value_datetime as next_clinical_contact_date, e.encounter_type FROM obs o
	INNER JOIN encounter e ON e.encounter_id = o.encounter_id
		WHERE o.voided = 0 AND e.voided = 0 AND e.encounter_type IN(6,18) 
			AND o.concept_id IN (1410,5096) AND e.location_id = :location
			AND e.encounter_datetime <= :endDate