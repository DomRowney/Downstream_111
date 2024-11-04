# helpers.py

## Function to round up to the nearest 5 for small number supression
def round_up_to_5(x):
        return ceil(x / 5) * 5

## Function to determine type of trauma symptom
def Trauma_Detect(x):
    if 'Blunt' in x:
        return 'Blunt'
    elif 'Penetrating' in x:
        return 'Penetrating' 
    elif  'Trauma' in x:
        return 'Other Trauma'
    else:
        return 'Not Trauma'
    
## Function to determine pregnancy
def Pregnancy_Detect(x):
    if 'Pregnant, Over 20 Weeks' in x:
        return 'Over 20 Weeks'
    elif 'Pregnant, Under 20 Weeks' in x:
        return 'Under 20 Weeks' 
    elif  'Pregnant' in x:
        return 'Other Pregnancy'
    else:
        return 'Not Pregnant'    
    
## Function replace string in col
def replace_thing(data,col,x):
    data.loc[:,col] = (data[col].str.replace(x,'', regex=True))
    return data    