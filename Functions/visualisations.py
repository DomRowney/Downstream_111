import pandas as pd
import numpy as np
## import plotly.express as px
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors


################################################################################
## Scatter plot of predicted and actual with error line
################################################################################

def plot_prediction_error(y_true, y_pred, title='Prediction Error Plot'):
    """Create a scatter plot comparing predicted and actual values, with an error line."""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Scatter plot of actual vs predicted values
    ax.scatter(y_true, y_pred, edgecolors=(0, 0, 0), alpha=0.7)
    ax.plot([y_true.min(), y_true.max()]
            , [y_true.min(), y_true.max()]
            , 'k--', lw=2, color='red')
    
    ax.set_xlabel('Actual Values')
    ax.set_ylabel('Predicted Values')
    ax.set_title(title)
    ax.grid(True)
    plt.show()


################################################################################
## Density plot of predicted and actual with error line
################################################################################

def plot_prediction_density_subplots(y_train, y_pred_train, y_test, y_pred_test):
    """Create two subplots with shared axes and a common logarithmic color scale."""
    fig, ax = plt.subplots(1, 2, figsize=(14, 6), sharex=True, sharey=True)
    
    # Create hexbin plot for training data
    hb1 = ax[0].hexbin(y_train, y_pred_train, gridsize=50, cmap='Blues', mincnt=1, 
                       norm=mcolors.LogNorm())
    ax[0].plot([y_train.min(), y_train.max()], [y_train.min(), y_train.max()], 
               'k--', lw=2, color='red')
    ax[0].set_title('Training Data - Prediction Density Plot')
    ax[0].set_xlabel('Actual Values')
    ax[0].set_ylabel('Predicted Values')
    ax[0].grid(True)

    # Create hexbin plot for test data
    hb2 = ax[1].hexbin(y_test, y_pred_test, gridsize=50, cmap='Blues', mincnt=1, 
                       norm=mcolors.LogNorm())
    ax[1].plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 
               'k--', lw=2, color='red')
    ax[1].set_title('Test Data - Prediction Density Plot')
    ax[1].set_xlabel('Actual Values')
    ax[1].grid(True)

    # Add a single colorbar for both subplots
    cb = fig.colorbar(hb1, ax=ax, orientation='vertical', fraction=0.03, pad=0.04)
    cb.set_label('Log Density')

    plt.tight_layout()
    plt.show()