# Notebooks
I've created this repository to share work relating to Jupyter notebooks and .NET interactive, subject to MIT licensing terms. This isn't a formal project, but *ad-hoc* sharing in the hope others might benefit from seeing what I did with software as it stood at the time; please be aware of the **As-is** nature of the offer, what you find here *may* be helpful to you but *may also* be unfit for your purpose, and things may not be updated as software changes. If you're in any doubt about the "As Is" nature of the offer, or what you're allowed to do, please read the `LICENSE` file. 

**GitHub will display .ipynb files**, but will filter out any Javascript so dynamic content like **Plotly charts do not work.**

Files included are: 
* SetNotebookToPS.ps1 - a script to modify the metadata inside a "polyglot" .ipynb file from the VS Code extension to be PowerShell first instead of a C# file with PowerShell *cells* 
* NotebookOutput.ps1 - a wrapper for Out-Display to make it easier to send HTML / SVG output to a cell
* Plotly.psm1 - a collection of functions to work with plotly. 
* Plotly.ipynb - plotly in use - in particular to demonstrate the functions in the .PSM1 
* this.ipynb - the git commands used to set up this repo. 
* exploration.ipynb - a quick walkthrough of the major features in .NET interactive notebooks (it uses Untitled2.png to show graphics included in markdown)
