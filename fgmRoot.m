function folder = fgmRoot()
    % fgmRoot - Folder containing the GUI MatlabFigureManager
    %
    %       folder = layoutRoot();
    %
    % The function returns the full path to the folder containing the
    % GUI MatlabFigureManager.

    % (c) 2018-2019 MIT License
    %   Created by Stephane Roussel & Olivier Leveque

    folder = fileparts(mfilename('fullpath'));
end