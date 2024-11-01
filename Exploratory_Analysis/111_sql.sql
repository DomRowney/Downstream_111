-- ############
-- Setup
-- ############

-- removes messages
SET NOCOUNT ON

DECLARE @StartDate AS DATE

SET @StartDate = 'REPLACE START DATE'

DROP TABLE IF EXISTS #111_calls

------------------------------------------------------------------

-- ############
-- 111 data
-- ############

SELECT 
--TOP 100
	'111' AS [Start_Location]
,	r.[Call ID]
,	r.[Pseudo NHS NUMBER] AS [Pseudo NHS Number]
,	CAST(r.[Start Date] AS DATE) AS [CallDate]
,	CAST(r.[Start Date] AS DATETIME) AS [Call Connect Time]
,	d.[Weekday_Name]
,	CAST(d.[Week_Start] AS DATE) AS [Week_Start]
,	d.[Fin_Year] AS [Financial Year]

,	CASE 
		WHEN r.[Report Post Code CCG Text] IN ('NHS County Durham CCG'
												,'NHS North Durham CCG'
												,'NHS Durham Dales Easington And Sedgefield CCG'
												,'Nhs Durham Dales, Easington And Sedgefield Ccg') THEN '84H'
		WHEN r.[Report Post Code CCG Text] IN ('NHS Newcastle Gateshead CCG'
												,'NHS Newcastle and Gateshead CCG'
												,'Nhs Gateshead Ccg'
												,'Nhs Newcastle West Ccg'
												,'Nhs Newcastle North And East Ccg') THEN '13T'
		WHEN r.[Report Post Code CCG Text] = 'Nhs North Tyneside Ccg' THEN '99C'
		WHEN r.[Report Post Code CCG Text] = 'Nhs Northumberland Ccg' THEN '00L'
		WHEN r.[Report Post Code CCG Text] = 'NHS South Tyneside CCG' THEN '00N'
		WHEN r.[Report Post Code CCG Text] = 'NHS Sunderland CCG'	  THEN '00P'
		WHEN r.[Report Post Code CCG Text] IN ('NHS Tees Valley CCG'
												,'NHS South Tees CCG'
												,'Nhs Hartlepool And Stockton-on-tees Ccg'
												,'Nhs Darlington Ccg') THEN '16C'
		WHEN  ISNULL(r.[Report Post Code CCG Text],'Unknown') = 'Unknown' THEN 'Unknown'
		ELSE 'Out of Area'
		END AS [Sub ICB Code]

,	CASE 
		WHEN r.[Report Post Code CCG Text] IN ('NHS County Durham CCG'
												,'NHS North Durham CCG'
												,'NHS Durham Dales Easington And Sedgefield CCG'
												,'Nhs Durham Dales, Easington And Sedgefield Ccg') THEN 'County Durham'
		WHEN r.[Report Post Code CCG Text] IN ('NHS Newcastle Gateshead CCG'
												,'NHS Newcastle and Gateshead CCG'
												,'Nhs Gateshead Ccg'
												,'Nhs Newcastle West Ccg'
												,'Nhs Newcastle North And East Ccg') THEN 'Newcastle Gateshead'
		WHEN r.[Report Post Code CCG Text] = 'Nhs North Tyneside Ccg' THEN 'North Tyneside'
		WHEN r.[Report Post Code CCG Text] = 'Nhs Northumberland Ccg' THEN 'Northumberland'
		WHEN r.[Report Post Code CCG Text] = 'NHS South Tyneside CCG' THEN 'South Tyneside'
		WHEN r.[Report Post Code CCG Text] = 'NHS Sunderland CCG'	  THEN 'Sunderland'
		WHEN r.[Report Post Code CCG Text] IN ('NHS Tees Valley CCG'
												,'NHS South Tees CCG'
												,'Nhs Hartlepool And Stockton-on-tees Ccg'
												,'Nhs Darlington Ccg') THEN 'Tees Valley'
		WHEN  ISNULL(r.[Report Post Code CCG Text],'Unknown') = 'Unknown' THEN 'Unknown'
		ELSE 'Out of Area'
		END AS [Sub ICB Name]
,	CAST('Unknown' AS varchar(max))	AS [GP Practice]
,	ISNULL(LEFT(r.[GP National ID],6),'Unknown')	AS [GP Practice Code]
,	CASE
		WHEN ISNULL(r.[Symptom_Group],'') = '' THEN  'Unknown'
		ELSE r.[Symptom_Group]
		END AS [Symptom_Group]
,	r.[Final Disposition Code]
,	CAST('Unknown' AS varchar(50))	AS [Disposition Group]
,	CAST('Unknown' AS varchar(100)) AS [Disposition]
,	ISNULL(r.[In_Out_Hours],
		CASE
			WHEN d.[Weekday_Name] IN ('Saturday','Sunday') THEN  'Out of Hours'
			WHEN d.[Bank_Holiday_Desc] IS NOT NULL THEN  'Out of Hours'
			WHEN DATEPART(HOUR, r.[Start Date]) BETWEEN 08 AND 17 THEN  'In Hours'
			ELSE 'Out of Hours'
			END) AS [In_Out_Hours]
,	CASE WHEN [Call Taker Triage Start] IS NOT NULL	THEN 'Yes' ELSE 'No' END AS [Call_Taker_Triages]
,	CASE WHEN [Nurse Triage Start] IS NOT NULL		THEN 'Yes' ELSE 'No' END AS [Clinical_Triages]
,	r.dmicAge				AS [Patient Age]
,	ISNULL(r.[Patient Sex Text],'Unknown')	AS [Patient Sex]
,	CAST(NULL AS varchar)		AS [Outcome ID]
,	CAST(NULL AS datetime)		AS [Outcome Datetime]
,	CAST(NULL AS varchar(25))	AS [Outcome Type]
,	CAST(NULL AS varchar(50))	AS [Outcome]
,	CAST(NULL AS varchar(50))	AS [Outcome Location Code]
,	CAST(NULL AS varchar(100))	AS [Outcome Location Name]
,	CAST(NULL AS float)			AS [Hours to Outcome]
INTO
	#111_calls
FROM
	[LocalDataNECS].[Ambulance].[vRX6_111] AS r
	LEFT JOIN
		[UK_Health_Dimensions].[dbo].[ref_Dates] AS d ON CAST(r.[Start Date] AS DATE) = d.[Full_Date]

WHERE
	1=1
	AND r.[Pseudo NHS NUMBER] IS NOT NULL
	AND r.[Pseudo NHS NUMBER] != ''
	AND CAST(r.[Start Date] AS DATE) >= @StartDate
	AND	[Report Post Code CCG Text] IN
					('NHS County Durham CCG'
					,'NHS North Durham CCG'
					,'NHS Durham Dales Easington And Sedgefield CCG'
					,'Nhs Durham Dales, Easington And Sedgefield Ccg'                  
					,'NHS Newcastle Gateshead CCG'
					,'NHS Newcastle and Gateshead CCG'
					,'Nhs Gateshead Ccg'                  
					,'Nhs Newcastle West Ccg'                  
					,'Nhs Newcastle North And East Ccg'                  
					,'Nhs North Tyneside Ccg'
					,'Nhs Northumberland Ccg'                  
					,'NHS South Tyneside CCG'
					,'NHS Sunderland CCG'
					,'NHS Tees Valley CCG'
					,'NHS South Tees CCG'
					,'Nhs Hartlepool And Stockton-on-tees Ccg'                  
					,'Nhs Darlington Ccg');  

------------------------------------------------------------------

-- ############
-- GP Practice
-- ############

UPDATE #111_calls
SET
	[GP Practice] = g.[Organisation_Name]
FROM
	[UK_Health_Dimensions].[ODS].[GP_Practices_And_Prescribing_CCs_SCD] AS g
WHERE 
	1=1
	AND [GP Practice Code] = g.[Organisation_Code]
	AND	g.[Is_Latest] = 1;

------------------------------------------------------------------

-- ############
-- Disposition
-- ############

UPDATE #111_calls
SET
	[Disposition Group]	= CASE 
							WHEN d.[MDS Primary Split] LIKE '%Recommended to Attend Other Service%' THEN  'Other Service'
							WHEN d.[MDS Primary Split] LIKE '%Not Recommended to Attend Other Service%' THEN  'No Recommendation'
							WHEN d.[MDS Primary Split] LIKE '%dispatch%' THEN  'Ambulance Dispatch'
							WHEN d.[MDS Primary Split] LIKE '%Primary and Community Care%' THEN  'Primary or Community Care'
							WHEN d.[MDS Primary Split] LIKE '%Recommended other outcome%'   THEN  'Recommended other outcome'
							WHEN d.[MDS Primary Split] = 'Recommended to attend another service' THEN  'Recommended other outcome'
							WHEN d.[MDS Primary Split] LIKE '%Recommended to Attend A&E%' THEN  'Urgent or Emergency Care'
							END
,	[Disposition]		= d.[UEC Lookup]
FROM [INFORMATIONTEAM].[dbo].[LU_DxCodes] AS d
WHERE
	1=1
	AND #111_calls.[Disposition Group] = 'Unknown'
	AND #111_calls.[Final Disposition Code] = d.[Kc Look Up];

------------------------------------------------------------------

-- ############
-- Symptom
-- ############

UPDATE #111_calls
SET	[Symptom_Group] = s.[Symptom_Group_Description]
FROM
	[UK_Health_Dimensions].[UEC_Analytics_Model].[Symptom_Groups_SCD] AS s
WHERE
	1=1
	AND s.[Is_Latest] = 1
	AND #111_calls.[Symptom_Group] LIKE 'SG%'
	AND #111_calls.[Symptom_Group] = s.[Symptom_Group_Code];

	
------------------------------------------------------------------

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
,	[Outcome Location Code] = a.[attendance.location.site]
FROM
	[LocalDataNECS].[ecds].[emergency_care]	AS a
	LEFT JOIN [LocalDataNECS].[ECDS].[commissioning.national_pricing.exclusion_reasons] AS x 
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

------------------------------------------------------------------

-- ############
-- Urgent Care
-- ############

UPDATE #111_calls
SET
	[Outcome ID]		= a.[Pseudo CaseID]
,	[Outcome Datetime]	= CAST(a.[CaseStarted] AS datetime)
,	[Outcome Type]		= 'Urgent Treatment Centre'
,	[Outcome]			= CASE
							WHEN a.[FollowUps] LIKE '%Patient Deceased%' THEN 'Died'
							WHEN a.[FollowUps] LIKE '%Admitted to Hospital%' THEN 'Admitted'			
							-- might need more follow ups
							WHEN a.[num walkins] = 1 THEN 'Urgent Treatment Centre'
							WHEN a.[num booked] = 1 THEN 'Urgent Treatment Centre'
							ELSE 'Unknown'
							END
,	[Outcome Location Code] = a.[CaseClosedAt]
,	[Outcome Location Name] = a.[CaseClosedAt]
FROM
	[LocalDataNECS].[Acute].[RXP_UrgentCareCentres] AS a
WHERE
	1=1
	AND a.[Pseudo NHSNumber] = #111_calls.[Pseudo NHS NUMBER]
	AND ISNULL(#111_calls.[Outcome Datetime],SYSDATETIME()) >  CAST(a.[CaseStarted] AS datetime)
	AND DATEDIFF(SECOND
                ,#111_calls.[Call Connect Time]
                ,CAST(a.[CaseStarted] AS datetime))
			BETWEEN 0 AND (90000-1) --seconds in 24 hours
	AND CAST(a.[CaseStarted] AS DATE) >= @StartDate
	AND ISNULL(a.[num walkins],0) + ISNULL(a.[num booked],0) > 0;


------------------------------------------------------------------

-- ############
-- Derived
-- ############

UPDATE #111_calls
SET [Outcome Location Name] = t.[Organisation_Name]
FROM
	[UK_Health_Dimensions].[ODS].[NHS_Trusts_And_Trust_Sites_SCD] AS t
WHERE
	1=1
	AND t.[Is_Latest] = 1
	AND #111_calls.[Outcome Location Code] = t.[Organisation_Code];

UPDATE #111_calls
SET [Outcome Type] = 'No UEC Contact'
,	[Outcome] = [Disposition]
,	[Outcome Location Code] = 'No UEC Contact'
,	[Outcome Location Name] = 'No UEC Contact'
,	[Hours to Outcome] = 0.0
WHERE [Outcome Type] IS NULL;


UPDATE #111_calls
SET [Hours to Outcome] = CAST(DATEDIFF(MINUTE
                ,[Call Connect Time]
                ,[Outcome Datetime])
					AS float)/60.0
WHERE [Outcome Datetime] IS NOT NULL;



------------------------------------------------------------------

-- ############
-- Output
-- ############

SELECT * FROM #111_calls