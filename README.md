


## Useful things

### Remove outputs from Jupyter notebooks from [Francois Maillet](https://blog.francoismaillet.com/recipe-strip-output-notebook)


This gist shows how to commit jupyter notebooks without output to git while keeping the notebooks outputs intact locally:

1. Add a filter to git config by running the following command in bash inside the repo:
   
    ```
   git config filter.strip-notebook-output.clean 'jupyter nbconvert --ClearOutputPreprocessor.enabled=True --to=notebook --stdin --stdout --log-level=ERROR'
    ```


3. Create a `.gitattributes` file inside the directory with the notebooks

4. Add the following to that file:

    ```
   *.ipynb filter=strip-notebook-output
    ```

After that, commit to git as usual. The notebook output will be stripped out in git commits, but it will remain unchanged locally.
