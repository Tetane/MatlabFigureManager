function sfg()
%% sfg() (save figures);
%
% Dependancies : Layout ToolBox.
%
% Display a GUI to easily save in different formats the figures currently opened.
% By selecting one figure you can choose the name of the files it will be saved in.
% By selecting multiple figures, they will be saved using the name of the figures.
% By pressing the 'f' key you can bring to focus the selected figures.
% If multiple selected figures have the same name they will be save as "Name(f#)". 

%% Figure creation
    % If sfg is already opened, don't open a new window
    set(0, 'ShowHiddenHandles', 'on')
    allFigures = get(0, 'Children');
    for iafig = 1:length(allFigures)
        if strcmp(allFigures(iafig).Tag, 'sfg')
            figure(allFigures(iafig));
            set(0, 'ShowHiddenHandles', 'Off')
            return
        end
    end
    set(0, 'ShowHiddenHandles', 'Off')
    clear allFigures
    
    % create the window
    screenSize = get(0,'ScreenSize');
    f_size = [240 , 400];
    f1 = figure(    'Position'          , [ceil((screenSize(3)-f_size(1))/2), ceil((screenSize(4)-f_size(2))/2), f_size(1), f_size(2)],...
                    'MenuBar'           , 'none', ...
                    'Toolbar'           , 'none', ...
                    'NumberTitle'       , 'off', ...
                    'Name'              , 'Save Figures',...
                    'IntegerHandle'     , 'off',...
                    'HandleVisibility'  , 'off',...
                    'Tag'               , 'sfg',...
                    'WindowKeyPressFcn' , @cb_keyPressed);
                
    handles = guihandles(f1);
    
%% GUI
    vbox = uix.VBox('Parent', f1);
        handles.list_box = uicontrol('Parent', vbox, 'Style', 'listbox');
        hbox = uix.HBox('parent', vbox);
            handles.check_fig = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.fig', 'Value', 1);
            handles.check_eps = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.eps', 'Value', 1);
            handles.check_pdf = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.pdf', 'Value', 0);
            handles.check_svg = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.svg', 'Value', 1);
            handles.check_png = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.png', 'Value', 0);
        set(hbox, 'widths', [-1,-1,-1,-1,-1]);
        buttonsHbox = uix.HBox('Parent', vbox);
            handles.refresh_button = uicontrol('Style', 'pushbutton', 'Parent', buttonsHbox, 'String', 'Refresh (f5)', 'CallBack', @cb_refresh, 'Tag', 'refresh_button');
            handles.save_button = uicontrol('Style', 'pushbutton', 'Parent', buttonsHbox, 'String', 'Save', 'CallBack', @cb_save, 'Enable', 'Off');
            handles.close_button = uicontrol('Style', 'pushbutton', 'Parent', buttonsHbox, 'String', 'Close', 'CallBack', @cb_closeFig, 'Enable', 'Off', 'Tag', 'close_button');
    set(vbox, 'heights', [-1, 25, 25]);
    save_tip = sprintf('If multiple figures are selected, the figure''s name will be used as the file name');
    set(handles.save_button, 'TooltipString', save_tip);
    
%% Get all the figures open in Matlab
    figures = get(0, 'children'); % list of the figures currently opened
    
    if ~isempty(figures)
        set(handles.save_button, 'Enable', 'On');
        set(handles.close_button, 'Enable', 'On');
        for ind = 1:length(figures)
            if strcmp(get(figures(ind), 'Name'), '')
                dispNames{ind} = ['Figure ' num2str(get(figures(ind), 'Number'))];
                figNames{ind} = ['Figure_' num2str(get(figures(ind), 'Number'))];
            else
                figNames{ind} = get(figures(ind), 'Name');
                dispNames{ind} = ['Figure ' num2str(get(figures(ind), 'Number')) ': ' get(figures(ind), 'Name')];
            end
        end
    else
        figNames{1} = '';
        dispNames{1} = '';
    end
    set(handles.list_box, 'String', dispNames, 'Max', length(dispNames)+1, 'Min', 1);
    handles.dispNames = dispNames;
    handles.figNames = figNames;
    handles.figures = figures;
    handles.path = '';
    
%% Put data in the figure handle
guidata(f1, handles);
    
%% Save CallBack function
    function cb_save(~, ~)
        data = guidata(gcbo);
%         allaxes = findall(data.figures(1), 'type', 'axes');
        if length(data.list_box.Value) == 1
            [files{1}, path] = uiputfile(fullfile(data.path, '*.*'), 'Save figure', fullfile(data.path, data.figNames{data.list_box.Value}));
            if path ~= 0
                [~, files{1}, ~] = fileparts(files{1}); % take only the name (get rid of the extension if there is one)
            end
        elseif length(data.list_box.Value) > 1
            path = uigetdir(data.path);
            files = data.figNames(data.list_box.Value);
        end
        if path ~= 0
            data.path = path;
        end
        wb = waitbar(0, '');
        nfig = length(data.list_box.Value);
        waitvalue = 0;
        for ind2 = 1:nfig
            if ~isequal(files{ind2},0) && ~isequal(path,0)
                set(findall(wb, 'String', ''), 'Interpreter', 'none');
                nbFormatMax = 5; % Total number of file format available
                currentFig = data.figures(data.list_box.Value(ind2));
                currentFileName = files{ind2};
                
                % Add the number of the figure "(f#)" if one or more file names are the same.
                for iFile = 1:length(files)
                    if strcmp(files{ind2}, files{iFile}) && ind2 ~= iFile
                        currentFileName = [files{ind2} '(f' num2str(get(currentFig, 'Number')) ')'];
                        break;
                    end
                end
                
                wbString = ['Saving: ' currentFileName];
%                 currentFilePath = fullfile(path, files{ind2});
                currentFilePath = fullfile(path, currentFileName);

                if data.check_fig.Value
                    waitbar(waitvalue/(nfig*nbFormatMax),wb, [wbString '.fig']);
                    saveas(currentFig, currentFilePath, 'fig');
                end
                waitvalue = waitvalue + 1;
                
                if data.check_eps.Value
                    waitbar(waitvalue/(nfig*nbFormatMax),wb, [wbString '.eps']);
                    saveas(currentFig, currentFilePath, 'epsc');
                end
                waitvalue = waitvalue + 1;
                
                if data.check_pdf.Value
                    waitbar(waitvalue/(nfig*nbFormatMax),wb, [wbString '.pdf']);
                    fig = currentFig;
                    fig.PaperPositionMode = 'auto';
                    fig.PaperUnits = 'points';
                    fig_pos = fig.PaperPosition;
                    fig.PaperSize = [fig_pos(3)+1 fig_pos(4)+1];
                    saveas(currentFig, currentFilePath, 'pdf');
                end
                waitvalue = waitvalue + 1;
                
                if data.check_svg.Value
                    waitbar(waitvalue/(nfig*nbFormatMax),wb, [wbString '.svg']);
                    saveas(currentFig, currentFilePath, 'svg');
                end
                waitvalue = waitvalue + 1;
                
                if data.check_png.Value
                    waitbar(waitvalue/(nfig*nbFormatMax),wb, [wbString '.png']);
                    saveas(currentFig, currentFilePath, 'png');
                end
                waitvalue = waitvalue + 1;
                
            end
        end
        close(wb);
        guidata(gcbo, data)
    end

%% Callbacks for the keyboard and the buttons
    function cb_keyPressed(~, event)
        data = guidata(gcbo);
%         disp(event)
        if strcmp(event.EventName, 'WindowKeyPress')
            key = event.Key;
            if strcmpi(key, 'f5')
                data = refresh(data);
            elseif strcmpi(key, 'f')
                focus(data);
            elseif strcmpi(key, 'delete')
                data = closefig(data);
            end
        end
        guidata(gcbo, data);
    end

    function cb_closeFig(~, ~)
        data = guidata(gcbo);
        data = closefig(data);
        guidata(gcbo, data);
    end

    function cb_refresh(~, ~)
        data = guidata(gcbo);
        data = refresh(data);
        guidata(gcbo, data);
    end

%% Functions
    function data = refresh(data)
%         set(data.list_box, 'Value', 1);
        newFigures = get(0, 'children');
        if ~isempty(newFigures)
            if ~isempty(data.figures)
                data.selected_figures = data.figures(data.list_box.Value);
            else
                data.selected_figures = 1;
            end
            
            set(data.save_button, 'Enable', 'On');
            set(data.close_button, 'Enable', 'On');
            for ind2 = 1:length(newFigures)
                if strcmp(get(newFigures(ind2), 'Name'), '')
                    dispNames_up{ind2} = ['Figure ' num2str(get(newFigures(ind2), 'Number'))];
                    figNames_up{ind2} = ['Figure_' num2str(get(newFigures(ind2), 'Number'))];
                else
                    figNames_up{ind2} = get(newFigures(ind2), 'Name');
                    dispNames_up{ind2} = ['Figure ' num2str(get(newFigures(ind2), 'Number')) ': ' get(newFigures(ind2), 'Name')];
                end
                
            end
            
            % Select in the new list the figures that were selected in the previous list
            Nselected = 0;
            for iNFig = 1:length(newFigures)
                for iSFig = 1:length(data.selected_figures)
                    if newFigures(iNFig) == data.selected_figures(iSFig)
                        Nselected = Nselected + 1;
                        newSelectedValues(Nselected) = iNFig;
                    end
                end
            end
            
            if Nselected ~= 0
                set(data.list_box, 'Value', newSelectedValues);
            else 
                set(data.list_box, 'Value', 1);
            end
            
        else % Empty list of figures
            set(data.list_box, 'Value', 1);
            figNames_up{1} = '';
            dispNames_up{1} = '';
            set(data.save_button, 'Enable', 'Off');
            set(data.close_button, 'Enable', 'Off');
        end
        set(data.list_box, 'String', dispNames_up, 'Max', length(dispNames_up)+1, 'Min', 1);
        data.figures = newFigures;
        data.dispNames = dispNames_up;
        data.figNames = figNames_up;
    end

    function focus(data)
        nfig = length(data.list_box.Value);
        for ind2 = 1:nfig
            figure(get(data.figures(data.list_box.Value(ind2)), 'Number'));
        end
    end
    
    function data = closefig(data)
        close(data.figures(data.list_box.Value));
        data = refresh(data);
    end
end

