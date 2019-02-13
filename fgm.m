function fgm()
    % FGM - FigManager
    %
    % Launch a GUI to manage and easily save figures currently opened.
    % Dependency : GUI Layout ToolBox.
    %
    % Shortcuts:
    %   - 'f' to focus on selected figures
    %   - 'f2' to focus on the text field 
    %   - 'f5' to refresh the figure list
    %   - 'del' to close selected figures
    %
    % (c) 2018 MIT License
    %   Created by Stephane Roussel <stephane.roussel@institutoptique.fr>
    %   Updated by Olivier Leveque <olivier.leveque@institutoptique.fr>
    
    % -- Layout ToolBox dependency checking
    try 
        layoutRoot();
    catch
        link = 'https://fr.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox';
        error(['Sorry, you need to install the <a href="' link '">GUI Layout Toolbox</a>.']);
    end
    
    % -- Main script
    if ~isFigManagerExist()
        h = createWindow();
        createInterface(h);
        updateInterface(h);
    end
    
    % -- Helper subfunctions
    function isexist = isFigManagerExist()
        set(0,'ShowHiddenHandles','On');
        allFigures = get(0,'Children');
        isexist = 0;
        for index = 1:length(allFigures)
            if strcmp(get(allFigures(index),'Tag'),'fgm')
                figure(allFigures(index));
                isexist = 1;
            end
        end
        set(0,'ShowHiddenHandles','Off');
    end
    function h = createWindow()
        screenSize = get(0,'ScreenSize');
        windowSize = [240, 400];
        h = figure(...
            'Position'          , ceil([(screenSize(3:4)-windowSize)/2,windowSize]),...
            'MenuBar'           , 'none', ...
            'Toolbar'           , 'none', ...
            'NumberTitle'       , 'off', ...
            'Name'              , 'FigManager',...
            'IntegerHandle'     , 'off',...
            'HandleVisibility'  , 'off',...
            'Tag'               , 'fgm',...
            'KeyPressFcn'       , @onKeyPressed);
%         handles = guihandles(h);
    end
    function createInterface(h)
        handles = guidata(h);
        
        vbox = uix.VBox('Parent', h);
        handles.list_box = uicontrol('Parent', vbox, 'Style', 'listbox', 'CallBack', @onClickList, 'KeyPressFcn' , @onKeyPressed);
            set(handles.list_box,'Max',4,'Min',0);
        
        editNamesHbox = uix.HBox('Parent', vbox);
            handles.editNames = uicontrol('Style', 'edit', 'Parent', editNamesHbox, 'HorizontalAlignment', 'left', 'KeyPressFcn', @onKeyPressed, 'tag', 'edit');
            handles.rename_button = uicontrol('Style', 'pushbutton', 'Parent', editNamesHbox, 'String', 'Rename', 'CallBack', @onRenameButton, 'KeyPressFcn' , @onKeyPressed, 'Enable', 'Off');
            set(editNamesHbox, 'widths', [-1 handles.rename_button.Extent(3) + 10]);

        hbox = uix.HBox('parent', vbox);
            handles.check_fig = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.fig', 'Value', 1, 'KeyPressFcn' , @onKeyPressed);
            handles.check_eps = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.eps', 'Value', 1, 'KeyPressFcn' , @onKeyPressed);
            handles.check_pdf = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.pdf', 'Value', 0, 'KeyPressFcn' , @onKeyPressed);
            handles.check_svg = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.svg', 'Value', 1, 'KeyPressFcn' , @onKeyPressed);
            handles.check_png = uicontrol('Parent', hbox, 'Style', 'checkbox', 'String', '.png', 'Value', 0, 'KeyPressFcn' , @onKeyPressed);
            set(hbox, 'widths', [-1,-1,-1,-1,-1]);

        buttonsHbox = uix.HBox('Parent', vbox);
            handles.refresh_button = uicontrol('Style', 'pushbutton', 'Parent', buttonsHbox, 'String', 'Refresh (f5)', 'CallBack', @onRefreshButton, 'Tag', 'refresh_button', 'KeyPressFcn' , @onKeyPressed);
            handles.save_button = uicontrol('Style', 'pushbutton', 'Parent', buttonsHbox, 'String', 'Save', 'CallBack', @onSaveButton, 'Enable', 'Off', 'KeyPressFcn' , @onKeyPressed);
            handles.close_button = uicontrol('Style', 'pushbutton', 'Parent', buttonsHbox, 'String', 'Close', 'CallBack', @onCloseButton, 'Enable', 'Off', 'Tag', 'close_button', 'KeyPressFcn' , @onKeyPressed);

        set(vbox, 'heights', [-1, 20, 25, 25]);

        save_tip = sprintf('If multiple figures are selected, the figure''s name will be used as the file name');
        set(handles.save_button,'TooltipString',save_tip);
        
        guidata(h,handles);
    end
    function updateInterface(h)
        handles = guidata(h);
        
        figures = get(0,'children');
        numberOfFigures = length(figures);
        
        if isempty(figures)
            state = 'Off';
            listFig = cell(1,3);
            listFig{1,2} = '';
            listFig{1,3} = '';
        else
            state = 'On';
            
            listFig = cell(numberOfFigures,3);
            for index = 1:numberOfFigures
                objectFig = figures(index);
                nameFig = get(objectFig,'Name');
                idFig = get(objectFig,'Number');
                if isempty(nameFig)
                    nameFig = 'Untitled';
                    set(objectFig,'Name',nameFig);
                end
                listFig{index,1} = idFig;
                listFig{index,2} = nameFig;
                listFig{index,3} = ['Figure ' num2str(idFig) ': ' nameFig];
            end
            listFig = sortrows(listFig);
        end
        
        set(handles.save_button,'Enable',state);
        set(handles.close_button,'Enable',state);
        set(handles.rename_button,'Enable',state);
        
        set(handles.list_box,'String',listFig(:,3));
        
        handles.listFigures = listFig;
        set(handles.editNames,'String',strjoin(nameSelectFigs(handles),';'));
        
        guidata(h,handles);
    end
    function id = idSelectFigs(handles)
        if ~all(size(handles.listFigures,1)>=get(handles.list_box,'Value'))
            set(handles.list_box,'Value',1);
        end
        id = cell2mat(handles.listFigures(get(handles.list_box,'Value'),1));
    end
    function name = nameSelectFigs(handles)
        if ~all(size(handles.listFigures,1)>=get(handles.list_box,'Value'))
            set(handles.list_box,'Value',1);
        end
        name = handles.listFigures(get(handles.list_box,'Value'),2);
    end

    % -- Callback functions
    function onKeyPressed(~,eventdata)
        handles = guidata(gcbo);
        
        if strcmp(eventdata.EventName, 'KeyPress')
            key = eventdata.Key;
            if strcmpi(key, 'f5')
                onRefreshButton();
            elseif strcmpi(key, 'f') && ~strcmp(eventdata.Source.Tag, 'edit') 
                idSelectedFigures = idSelectFigs(handles);
                for i = 1:length(idSelectedFigures)
                    figure(idSelectedFigures(i));
                end
            elseif (strcmpi(key, 'delete') || strcmpi(key, 'backspace')) && ~strcmp(eventdata.Source.Tag, 'edit')
                onCloseButton();
            elseif strcmpi(key, 'f2')
                uicontrol(handles.editNames);
            elseif strcmpi(key, 'return') && strcmp(eventdata.Source.Tag, 'edit')
                pause(0.1)
                onRenameButton();
            end
        end
        
    end

    function onSaveButton(~,~)
        handles = guidata(gcbo);
        idSelectedFigures = idSelectFigs(handles);
        nameSelectedFigures = nameSelectFigs(handles);
        check = nonzeros([...
            handles.check_fig.Value,...
            handles.check_eps.Value*2,...
            handles.check_pdf.Value*3,...
            handles.check_svg.Value*4,...
            handles.check_png.Value*5]);
        ext = {'*.fig';'*.eps';'*.pdf';'*.svg';'*.png'};
        formats = {'fig';'epsc';'pdf';'svg';'png'};
        ext = ext(check);
        formats = formats(check);
        if length(idSelectedFigures)==1
            [file,path] = uiputfile(ext,'FigManager',char(nameSelectedFigures(1)));
            if all(path~=0)
                [~,namefile,~] = fileparts(file);
                nameSelectedFigures{1} = namefile;
            end
        else
            path = uigetdir(pwd,'FigManager');
        end
        if all(path~=0)
            wb = waitbar(0,'');
            for i = 1:length(idSelectedFigures)
                for j = 1:length(formats)
                    waitbar((i+j)/(length(formats)+length(idSelectedFigures)),wb,['Saving : ' char(nameSelectedFigures(i))]);
                    fullFilePath = fullfile(path,char(nameSelectedFigures(i)));
                    extension = char(ext(j));
                    extension = extension(2:end);
                    if isfile([fullFilePath,extension])
                        warning([char(nameSelectedFigures(i)) extension ' can''t be saved because this file already exists.']);
                    else
                        currentFig = figure(idSelectedFigures(i));
                        if strcmp(char(formats(j)),'pdf')
                            currentFig.PaperPositionMode = 'auto';
                            currentFig.PaperUnits = 'points';
                            currentFig.PaperSize = [currentFig.PaperPosition(3)+1 currentFig.PaperPosition(4)+1];
                        end
                        saveas(currentFig,fullFilePath,char(formats(j)));
                    end
                end
            end
            close(wb);
        end
    end
    function onCloseButton(~,~)
        handles = guidata(gcbo);
        close(idSelectFigs(handles));
        set(handles.list_box,'Value',1);
        updateInterface(gcbo);
    end
    function onRenameButton(~,~)
        handles = guidata(gcbo);
        idSelectedFigures = idSelectFigs(handles);
        newNames = split(get(handles.editNames,'String'),';');
        for index = 1:length(idSelectedFigures)
            set(figure(idSelectedFigures(index)),'Name',newNames{index});
        end
        updateInterface(gcbo);
    end
    function onRefreshButton(~,~)
        handles = guidata(gcbo);
        set(handles.list_box,'Value',1);
        updateInterface(gcbo);
    end
    function onClickList(~,~)
        updateInterface(gcbo);
        handles = guidata(gcbo);
        persistent chk; % Change to non persistent variable !
        if ~isempty(handles.listFigures{1,1}) % Trouver une autre condition
            if isempty(chk)
                chk = 1;
                pause(0.3);
                chk = [];
            else
                chk = [];
                figure(idSelectFigs(handles));
                uicontrol(handles.editNames);
            end
        end
    end
end