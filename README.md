# MatlabFigureManager

MatlabFigureManager is a simple Matlab GUI that shows a list of all the figures opened and allows to easily save them in different file formats.
The current supported formats are: .fig, .eps, .pdf, .svg, .png. (Other file formats that are supported by Matlab can easily be added.)

Dependency:
* [GUI Layout Toolbox](https://mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox)

## Installation
To install MatlabFigureManager, use these following lines in your MATLAB Command Window.
```
folder = unzip(websave([userpath,'\MatlabFigureManager'],'https://github.com/Tetane/MatlabFigureManager/archive/1.0.zip'),userpath);
addpath(genpath([userpath,'\MatlabFigureManager-1.0']));
delete([userpath,'\MatlabFigureManager.zip']);
fgm;
```

To launch automatically MatlabFigureManager when MATLAB starts, use these following lines in your MATLAB Command Window.
```
msg = "addpath(genpath('"+userpath+"\MatlabFigureManager-1.0'));fgm;";
id = fopen('startup.m','a');
fwrite(id,msg);
fclose(id);
```