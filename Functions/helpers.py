# helpers.py

import pandas as pd
import numpy as np
from math import ceil


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


## Replaces low frequency sites with 'OTHER SITE'
def aggregate_sites(x):
    keep_sites = [  'No UEC Contact'
                ,'UNIVERSITY HOSPITAL OF NORTH TEES'
                ,'THE ROYAL VICTORIA INFIRMARY'
                ,'NORTHUMBRIA SPECIALIST EMERGENCY CARE HOSPITAL'
                ,'UNIVERSITY HOSPITAL OF NORTH DURHAM'
                ,'THE JAMES COOK UNIVERSITY HOSPITAL'
                ,'SUNDERLAND ROYAL HOSPITAL'
                ,'QUEEN ELIZABETH HOSPITAL'
                ,'DARLINGTON MEMORIAL HOSPITAL'
                ,'UNIVERSITY HOSPITAL OF HARTLEPOOL'
                ,'SOUTH TYNESIDE DISTRICT HOSPITAL'
                ,'WANSBECK HOSPITAL'
                ,'REDCAR PRIMARY CARE HOSPITAL'
                ]
    if x in keep_sites:
        return x
    else:
        return 'OTHER SITE'
    
## calculates accuracy for keras based forecasts
def keras_calculate_accuracy(model, X_train_sc, X_test_sc, y_train, y_test):
    """Calculate and print accuracy of training and test data fits"""    
    
   # Predict on training and test data
    y_pred_train = model.predict(X_train_sc).flatten()
    y_pred_test = model.predict(X_test_sc).flatten()

    # Calculate Mean Absolute Error (MAE) for training and test sets
    mae_train = np.mean(np.abs(y_pred_train - y_train))
    mae_test = np.mean(np.abs(y_pred_test - y_test))
    
    # Calculate Mean Squared Error (MSE) for training and test sets
    mse_train = np.mean((y_pred_train - y_train) ** 2)
    mse_test = np.mean((y_pred_test - y_test) ** 2)

    # Calculate Root Mean Squared Error (RMSE) for training and test sets
    rmse_train = np.sqrt(mse_train)
    rmse_test = np.sqrt(mse_test)

    # Calculate NRMSE (Normalized RMSE)
    range_y_train = np.max(y_train) - np.min(y_train)  # Range of y_train
    range_y_test = np.max(y_test) - np.min(y_test)  # Range of y_test
    nrmse_train = rmse_train / range_y_train
    nrmse_test = rmse_test / range_y_test

    # Calculate R^2 for training and test sets
    ss_total_train = np.sum((y_train - np.mean(y_train)) ** 2)
    ss_total_test = np.sum((y_test - np.mean(y_test)) ** 2)
    ss_residual_train = np.sum((y_pred_train - y_train) ** 2)
    ss_residual_test = np.sum((y_pred_test - y_test) ** 2)

    r2_train = 1 - (ss_residual_train / ss_total_train)
    r2_test = 1 - (ss_residual_test / ss_total_test)

    # Print the results
    print(f'Training MAE: {mae_train:.3f}')
    print(f'Test MAE: {mae_test:.3f}')
    print(f'Training MSE: {mse_train:.3f}')
    print(f'Test MSE: {mse_test:.3f}')
    print(f'Training NRMSE: {nrmse_train:.3f}')
    print(f'Test NRMSE: {nrmse_test:.3f}')
    print(f'Training R2: {r2_train:.3f}')
    print(f'Test R2: {r2_test:.3f}')

## calculates baseline accuracy for keras based forecasts
def keras_calculate_baseline_accuracy(y_pred_train,y_pred_test,y_train, y_test):
    """Calculate and print accuracy of training and test data fits"""    

    # Calculate Mean Absolute Error (MAE) for training and test sets
    mae_train = np.mean(np.abs(y_pred_train - y_train))
    mae_test = np.mean(np.abs(y_pred_test - y_test))
    
    # Calculate Mean Squared Error (MSE) for training and test sets
    mse_train = np.mean((y_pred_train - y_train) ** 2)
    mse_test = np.mean((y_pred_test - y_test) ** 2)

    # Calculate Root Mean Squared Error (RMSE) for training and test sets
    rmse_train = np.sqrt(mse_train)
    rmse_test = np.sqrt(mse_test)

    # Calculate NRMSE (Normalized RMSE)
    range_y_train = np.max(y_train) - np.min(y_train)  # Range of y_train
    range_y_test = np.max(y_test) - np.min(y_test)  # Range of y_test
    nrmse_train = rmse_train / range_y_train
    nrmse_test = rmse_test / range_y_test

    # Calculate R^2 for training and test sets
    ss_total_train = np.sum((y_train - np.mean(y_train)) ** 2)
    ss_total_test = np.sum((y_test - np.mean(y_test)) ** 2)
    ss_residual_train = np.sum((y_pred_train - y_train) ** 2)
    ss_residual_test = np.sum((y_pred_test - y_test) ** 2)

    r2_train = 1 - (ss_residual_train / ss_total_train)
    r2_test = 1 - (ss_residual_test / ss_total_test)

    # Print the results
    print(f'Training MAE: {mae_train:.3f}')
    print(f'Test MAE: {mae_test:.3f}')
    print(f'Training MSE: {mse_train:.3f}')
    print(f'Test MSE: {mse_test:.3f}')
    print(f'Training NRMSE: {nrmse_train:.3f}')
    print(f'Test NRMSE: {nrmse_test:.3f}')
    print(f'Training R2: {r2_train:.3f}')
    print(f'Test R2: {r2_test:.3f}')