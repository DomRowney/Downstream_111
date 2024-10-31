DECLARE 
 @StartDate AS DATE
,@mainend AS DATE
,@dailystart AS DATE
,@dailyend AS DATE
,@WeeklyEND AS DATE
,@Latest_Month_end AS DATE
,@Latest_Month_start AS DATE;

Set @StartDate = '2023-01-01'
Set @MainEND   = (select max(a.[Start Date]) from [LocalDataNECS].[Ambulance].[vRX6_111] AS a LEFT JOIN [Reference].[dbo].[ref_Dates] AS b on CAST(a.[Start Date] AS DATE) = b.Full_Date where b.Weekday_Short_Name ='sun')

-- the below needs amending AS soon AS the 111 weekly flow restarts 

--SET @Latest_Month_end = (Select MAX(b.Month_End) from [TB4UW_Reporting].[NEAS111].[CallData] AS a LEFT JOIN [Reference].[dbo].[ref_Dates] AS b on CAST(a.[CALL CONNECT DATETIME] AS DATE) = b.Full_Date)-- automated do not amend unless needed. This bit finds the latest month start
--SET @Latest_Month_start = (Select MAX(b.Month_start) from [TB4UW_Reporting].[NEAS111].[CallData] AS a LEFT JOIN [Reference].[dbo].[ref_Dates] AS b on CAST(a.[CALL CONNECT DATETIME] AS DATE) = b.Full_Date)--

SET @Latest_Month_end = (Select MAX(b.Month_End) from [LocalDataNECS].[Ambulance].[vRX6_111] AS a LEFT JOIN [Reference].[dbo].[ref_Dates] AS b on CAST(a.[Start Date] AS DATE) = b.Full_Date)-- automated do not amend unless needed. This bit finds the latest month start
SET @Latest_Month_start = (Select MAX(b.Month_start) from [LocalDataNECS].[Ambulance].[vRX6_111] AS a LEFT JOIN [Reference].[dbo].[ref_Dates] AS b on CAST(a.[Start Date] AS DATE) = b.Full_Date)--

DROP TABLE IF EXISTS #111_calls

SELECT 
TOP 100
	'111' AS [Indicator]
,	r.[Call ID]
,	r.[Pseudo NHS NUMBER]
,	CAST(r.[Start Date] AS DATE) AS [CallDate]
,	CAST(r.[Start Date] AS DATETIME) AS [Call Connect Time]
,	d.[Weekday_Name]
,	CAST(d.[Week_Start] AS DATE) AS [Week_Start]
,	d.[Fin_Year] AS [Financial Year]
,	CASE 
		WHEN r.[Report Post Code CCG Text] in ('NHS Newcastle Gateshead CCG','NHS Northumberland CCG','NHS North Tyneside CCG') THEN  'North ICP'
		WHEN r.[Report Post Code CCG Text] in ('NHS Sunderland CCG','NHS South Tyneside CCG','NHS County Durham CCG','NHS Durham Dales Easington And Sedgefield CCG','NHS North Durham CCG') THEN  'Central ICP'
		WHEN r.[Report Post Code CCG Text] in ('NHS Hartlepool And Stockton-on-tees CCG','NHS South Tees CCG','NHS Darlington CCG','NHS Tees Valley CCG') THEN  'South ICP'
		ELSE 'Unknown'
		END AS [ICP]
,	CASE 
		WHEN r.[Report Post Code CCG Text] In ('NHS County Durham CCG','NHS Durham Dales Easington And Sedgefield CCG','NHS North Durham CCG') THEN  'County Durham Sub ICB'
		WHEN r.[Report Post Code CCG Text] In ('NHS Hartlepool And Stockton-on-tees CCG','NHS South Tees CCG','NHS Darlington CCG','NHS Tees Valley CCG') THEN  'Tees Valley Sub ICB'
		ELSE replace(Replace(isnull([Report Post Code CCG Text],'Unknown'),'CCG','Sub ICB'),'NHS ','')
		END AS [Sub ICB]
,	ISNULL(f.[PCNDescription],'Unknown')AS [PCN]
,	ISNULL(f.[PracticeDesc],'Unknown')	AS [GP Practice]
,	ISNULL(f.[PracticeCode],'Unknown')	AS [Practice_Code]
,	CASE
		WHEN ISNULL(r.[Symptom_Group],'') = '' THEN  'Unknown'
		WHEN r.[Symptom_Group] LIKE 'SG%' THEN  sg.[Symptom_Group_Description]
		ELSE r.[Symptom_Group]
		END AS [Symptom_Group]
,	CASE
		WHEN ISNULL(dp.[disposition],'') = '' THEN 'Unknown'
		ELSE dp.[disposition]
		END AS [Disposition_Group]
,	CASE
	WHEN ISNULL(dp.[UEC Lookup],'') = '' THEN 'Unknown'
	ELSE dp.[UEC Lookup]
	END AS [UEC_Lookup]
,	ISNULL(r.[In_Out_Hours],
		CASE
			WHEN d.[Weekday_Name] IN ('Saturday','Sunday') THEN  'Out of Hours'
			WHEN d.[Bank_Holiday_Desc] IS NOT NULL THEN  'Out of Hours'
			WHEN DATEPART(HOUR, r.[Start Date]) BETWEEN 08 AND 17 THEN  'In Hours'
			ELSE 'Out of Hours'
			END) AS [In_Out_Hours]
,	CASE WHEN [Last_Interaction_Type] = 'Non-PW Clinician'	THEN  1 ELSE 0 END AS [CAS Input]
,	CASE WHEN [Call Connect Time] IS NOT NULL				THEN  1 ELSE 0 END AS [Contacts]
,	CASE WHEN [Call Taker Triage Start] IS NOT NULL			THEN  1 ELSE 0 END AS [Call_Taker_Triages]
,	CASE WHEN [Nurse Triage Start] IS NOT NULL				THEN  1 ELSE 0 END AS [Clinical_Triages]
,	CASE WHEN (CAST(r.[Start Date] AS DATEtime) <= CASE WHEN @mainend = @Latest_Month_end THEN  CAST(r.[Start Date] AS DATEtime) else dateadd(dd,-1,@Latest_Month_start) end) THEN  1 else 0 end AS Latest_COMPLETE_FM_To_DATE
,	r.dmicAge				AS [Patient Age]
,	ISNULL(r.[Patient Sex Text],'Unknown')	AS [Patient Sex]
,	CAST(NULL AS varchar)		AS [Outcome ID]
,	CAST(NULL AS datetime)		AS [Outcome Datetime]
,	CAST(NULL AS varchar(25))	AS [Outcome Type]
,	CAST(NULL AS varchar(50))	AS [Outcome]
,	CAST(NULL AS float)			AS [Hours to Outcome]
INTO
	#111_calls
FROM
	[LocalDataNECS].[Ambulance].[vRX6_111] AS r
	LEFT JOIN
		[UK_Health_Dimensions].[dbo].[ref_Dates] AS d ON CAST(r.[Start Date] AS DATE) = d.[Full_Date]
	LEFT JOIN (	SELECT DISTINCT
						[Kc Look Up]
					,	CASE 
							WHEN [MDS Primary Split] like '%Recommended to Attend Other Service%' THEN  'Other Service'
							WHEN [MDS Primary Split] like '%Not Recommended to Attend Other Service%' THEN  'No Recommendation'
							WHEN [MDS Primary Split] like '%dispatch%' THEN  'Ambulance Dispatch'
							WHEN [MDS Primary Split] like '%Primary and Community Care%' THEN  'Primary or Community Care'
							WHEN [MDS Primary Split] like '%Recommended other outcome%'   THEN  'Recommended other outcome'
							WHEN [MDS Primary Split] = 'Recommended to attend another service' THEN  'Recommended other outcome'
							WHEN [MDS Primary Split] like '%Recommended to Attend A&E%' THEN  'Urgent or Emergency Care'
							END AS Disposition,[UEC Lookup]
					FROM [INFORMATIONTEAM].[dbo].[LU_DxCodes]
				)	AS dp 
				ON r.[Final Disposition Code] = dp.[Kc Look Up]		
	LEFT JOIN (	SELECT DISTINCT
				[PracticeCode],PracticeDesc,CCGDesc,CCGCode,LocalityDesc,legacy_CCG_Desc,PCNDescription
				   FROM [PDC-SYS-SQL-142].[Raidr].[dbo].[LU_All_Practice_exclude_SurryHeatlands_1610_2023])
				   AS f on 
				   LEFT([PracticeCode],1) != 'v'
				   AND LEFT([GP National ID],6) = f.[PracticeCode]
				   AND (CASE 
						WHEN r.[Report Post Code CCG Text] IN ('NHS County Durham CCG','NHS Durham Dales Easington And Sedgefield CCG','NHS North Durham CCG') THEN  'NHS County Durham CCG'
						WHEN r.[Report Post Code CCG Text] IN ('NHS Hartlepool And Stockton-on-tees CCG','NHS South Tees CCG','NHS Darlington CCG','NHS Tees Valley CCG') THEN  'NHS Tees Valley CCG'
						ELSE r.[Report Post Code CCG Text]
						END) = f.[CCGDesc]
	LEFT JOIN (	SELECT DISTINCT
						[Symptom_Group_Code]
					,	[Symptom_Group_Description]
					FROM [UK_Health_Dimensions].[UEC_Analytics_Model].[Symptom_Groups_SCD]
				) AS sg
				ON r.[Symptom_Group] = SG.[Symptom_Group_Code]
WHERE
	1=1
	AND CAST(r.[Start Date] AS DATE) >= @StartDate
	AND	[Report Post Code CCG Text] IN ('NHS Northumberland CCG'
									,'NHS Newcastle Gateshead CCG'
									,'NHS North Tyneside CCG'
									,'NHS Hartlepool And Stockton-on-tees CCG'
									,'NHS South Tees CCG'
									,'NHS Darlington CCG'
									,'NHS Tees Valley CCG'
									,'NHS South Tyneside CCG'
									,'NHS Sunderland CCG'
									,'NHS County Durham CCG'
									,'NHS Durham Dales Easington And Sedgefield CCG'
									,'NHS North Durham CCG')

-- ############
-- A&E
-- ############

UPDATE #111_calls
SET
	[Outcome ID]		= a.[PRIMARYKEY_ID]
,	[Outcome Datetime]	= CAST(a.[attendance.arrival.date] AS datetime)+CAST(a.[attendance.arrival.time] AS datetime)
,	[Outcome Type]		= CASE 
							WHEN a.[attendance.location.department_type] IN ('01','02') THEN 'Emergency Care'
							WHEN a.[attendance.location.department_type] IN ('03','04') THEN 'Urgent Treatment Centre'
							END 
,	[Outcome]			= ISNULL(b.[ECDS_Group1],'Unknown')
FROM
	[LocalDataNECS].[ecds].[emergency_care]	AS a
	LEFT JOIN	(	SELECT DISTINCT [PRIMARYKEY_ID]
					FROM [LocalDataNECS].[ECDS].[commissioning.national_pricing.exclusion_reasons]
					) AS x 
				ON a.[PRIMARYKEY_ID] = x.[PRIMARYKEY_ID]
	LEFT JOIN ( SELECT DISTINCT
						[SNOMED_Code]
					,	ISNULL([SNOMED_Description],[ECDS_Description]) AS [ECDS_Description]
					,	[ECDS_Group1]
				FROM [UK_Health_Dimensions].[ECDS_TOS].[Code_Sets]
				WHERE 
					1=1
					AND [Sheet_Name] LIKE '%20.4 DISCHARGE DESTINATION%'
					AND [file_name] = '20200408141953\20200408141953_ecds_data_set_tos_v2.1.1.1_covid-19 - fixed.xlsx'
				) AS b
				ON a.[attendance.discharge.destination.code] = b.[SNOMED_Code]
WHERE
	1=1
	AND a.[patient.nhs_number.value Pseudo] = #111_calls.[Pseudo NHS NUMBER]
	AND ISNULL(#111_calls.[Outcome Datetime],SYSDATETIME()) >  CAST(a.[attendance.arrival.date] AS datetime)+CAST(a.[attendance.arrival.time] AS datetime)
	AND DATEDIFF(SECOND
                ,#111_calls.[Call Connect Time]
                ,CAST(a.[attendance.arrival.date] AS datetime)+CAST([attendance.arrival.time] AS datetime))
			BETWEEN 0 AND (90000-1) --seconds in 24 hours
	AND CAST(a.[attendance.arrival.date] AS DATE) >= @StartDate
	AND a.[attendance.location.department_type] in ('01','02','03','04')
	AND a.[attendance.location.hes_provider_3] in ('RTD','RR7','RTF','RXP','RVW','RTR','R0B','RNN')
	AND x.[PRIMARYKEY_ID] IS NULL -- exclude streamed attendances - only looking at actual triaged attendances !! 
	;

-- ############
-- Urgent Care
-- ############

UPDATE #111_calls
SET
	[Outcome ID]		= a.[PRIMARYKEY_ID]
,	[Outcome Datetime]	= CAST(a.[CaseStarted] AS datetime)
,	[Outcome Type]		= 'Urgent Treatment Centre'
,	[Outcome Type]		= CASE
							WHEN a.[FollowUps] LIKE '%Patient Deceased%' THEN 'Died'
							WHEN a.[FollowUps] LIKE '%Admitted to Hospital%' THEN 'Admitted'			
							-- might need more follow ups
							WHEN a.[num walkins] = 1 THEN 'Urgent Treatment Centre'
							WHEN a.[num booked] = 1 THEN 'Urgent Treatment Centre'
							ELSE 'Unknown'
							END
FROM
	[LocalDataNECS].[Acute].[RXP_UrgentCareCentres] AS a
WHERE
	1=1
	AND a.[Pseudo NHSNumber] = #111_calls.[Pseudo NHS NUMBER]
	AND ISNULL(#111_calls.[Outcome Datetime],SYSDATETIME()) >  CAST(a.[attendance.arrival.date] AS datetime)+CAST(a.[attendance.arrival.time] AS datetime)
	AND DATEDIFF(SECOND
                ,#111_calls.[Call Connect Time]
                ,CAST(a.[CaseStarted] AS datetime))
			BETWEEN 0 AND (90000-1) --seconds in 24 hours
	AND CAST(a.[attendance.arrival.date] AS DATE) >= @StartDate
	AND ISNULL(a.[num walkins],0) + ISNULL(a.[num booked],0) > 0;
