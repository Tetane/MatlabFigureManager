function fgm()
    % FGM - MatlabFigureManager
    %
    % Launch a GUI to manage and easily save figures currently opened.
    % Dependency : GUI Layout ToolBox.
    %
    % Saving figures:
    %   - If one figure is selected the name of the file can be choosen at the moment of saving.
    %   (Default file name will be the name of the figure)
    %   - If Multiple figures are selected, the files names will be the names of the figures.
    %   - If a figure has no name, the file's name will be "Figure_#" ("#" being the figure's number).
    %
    % Shortcuts:
    %   - 'f' to focus on selected figures
    %   - 'f2' to focus on the text field 
    %   - 'f5' to refresh the figure list
    %   - 'del' or 'backSpace' to close selected figures
    
    % (c) 2018-2019 MIT License
    %   Created by Stephane Roussel <stephane.roussel@institutoptique.fr>
    %   Updated by Olivier Leveque <olivier.leveque@institutoptique.fr>
    
    % -- Layout ToolBox dependency checking
    try 
        layoutRoot();
    catch
        link = 'https://fr.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox';
        error('Sorry, you need to install the <a href="%s">GUI Layout Toolbox</a>.',link);
    end
    
    % -- Updates checking
    gitUser = 'Tetane';
    gitRepo = 'MatlabFigureManager';
    fgmCurrentTag = '1.0';
    json = webread(['https://api.github.com/repos/',gitUser,'/',gitRepo,'/releases/latest']);
    if ~all(json.tag_name==fgmCurrentTag)
        warning('Your are using FigManager v%s\nA new version (v%s) is available. You can download it <a href="%s">here</a>.',fgmCurrentTag,json.tag_name,json.html_url);
    end
    
    % -- Main script
    if ~isFgmExist()
        data = loadBackup();
        h = createWindow();
        createInterface(h,data);
        updateInterface(h);
    end
    
    % -- GUI subfunctions
    function fgmExists = isFgmExist()
        set(0,'ShowHiddenHandles','On');
        allFigures = get(0,'Children');
        fgmExists = 0;
        for index = 1:length(allFigures)
            if strcmp(get(allFigures(index),'Tag'),'fgm')
                figure(allFigures(index));
                fgmExists = 1;
            end
        end
        set(0,'ShowHiddenHandles','Off');
    end
    function data = loadBackup()
        data.dataFilePath = [fgmRoot(),filesep,'backup.mat'];
        try
            load(data.dataFilePath,'selectedFormats','lastpath');
        catch
            selectedFormats = [1,1,0,1,0];
            lastpath = pwd; % current folder
        end
        data.selectedFormats = selectedFormats;
        data.lastpath = lastpath;
    end
    function h = createWindow()
        screenSize = get(0,'ScreenSize');
        windowSize = [240,400];
        h = figure(...
            'Position'          , ceil([(screenSize(3:4)-windowSize)/2,windowSize]),...
            'MenuBar'           , 'none', ...
            'Toolbar'           , 'none', ...
            'NumberTitle'       , 'off', ...
            'Name'              , 'FigManager',...
            'IntegerHandle'     , 'off',...
            'HandleVisibility'  , 'off',...
            'Tag'               , 'fgm',...
            'KeyPressFcn'       , @onKeyPressed,...
            'CloseRequestFcn'   , @onCloseFgm);
%         handles = guihandles(h);
    end
    function createInterface(h,data)
        handles = guidata(h);
        
        vbox = uix.VBox('Parent',h);
        
        % Fig list section
        handles.list_box = uicontrol('Parent',vbox,'Style','listbox','CallBack',@onClickList,'KeyPressFcn',@onKeyPressed);
        set(handles.list_box,'Max',4,'Min',0);
        
        % Fig list context menu
        menu_listbox = uicontextmenu('Parent',h);
        handles.context_menu.save_button = uimenu(menu_listbox,'Text','Save (Ctrl+S)','CallBack',@onSaveButton,'Enable','Off');
        handles.context_menu.close_button = uimenu(menu_listbox,'Text','Close (Del)','CallBack',@onCloseButton,'Enable','Off');
        handles.context_menu.focus_button = uimenu(menu_listbox,'Text','Focus (F)','CallBack',@onFocusCtxtmenuButton,'Enable','Off');
        handles.context_menu.rename_button = uimenu(menu_listbox,'Text','Rename (F2)','CallBack',@onRenameCtxtmenuButton,'Enable','Off');
        set(handles.list_box,'UiContextMenu',menu_listbox);
        
        % Rename section
        editNamesHbox = uix.HBox('Parent',vbox);
        handles.editNames = uicontrol('Style','edit','Parent',editNamesHbox,'HorizontalAlignment','left','KeyPressFcn',@onKeyPressed,'tag','edit');
        handles.rename_button = uicontrol('Style','pushbutton','Parent',editNamesHbox,'String','Rename','CallBack',@onRenameButton,'KeyPressFcn' , @onKeyPressed, 'Enable', 'Off');
        set(editNamesHbox,'widths',[-1,handles.rename_button.Extent(3)+10]);

        % Fig extensions section
        hbox = uix.HBox('parent', vbox);
        handles.check_fig = uicontrol('Parent',hbox,'Style','checkbox','String','.fig','Value',data.selectedFormats(1),'KeyPressFcn',@onKeyPressed);
        handles.check_eps = uicontrol('Parent',hbox,'Style','checkbox','String','.eps','Value',data.selectedFormats(2),'KeyPressFcn',@onKeyPressed);
        handles.check_pdf = uicontrol('Parent',hbox,'Style','checkbox','String','.pdf','Value',data.selectedFormats(3),'KeyPressFcn',@onKeyPressed);
        handles.check_svg = uicontrol('Parent',hbox,'Style','checkbox','String','.svg','Value',data.selectedFormats(4),'KeyPressFcn',@onKeyPressed);
        handles.check_png = uicontrol('Parent',hbox,'Style','checkbox','String','.png','Value',data.selectedFormats(5),'KeyPressFcn',@onKeyPressed);
        set(hbox,'widths',[-1,-1,-1,-1,-1]);

        % Buttons section
        buttonsHbox = uix.HBox('Parent',vbox);
        handles.refresh_button = uicontrol('Style','pushbutton','Parent',buttonsHbox,'String','Refresh (f5)','CallBack',@onRefreshButton,'Tag','refresh_button','KeyPressFcn',@onKeyPressed);
        handles.save_button = uicontrol('Style','pushbutton','Parent',buttonsHbox,'String','Save','CallBack',@onSaveButton,'Enable','Off','KeyPressFcn',@onKeyPressed);
        set(handles.save_button,'TooltipString',sprintf('If multiple figures are selected, the figure''s name will be used as the file name'));
        handles.close_button = uicontrol('Style','pushbutton','Parent',buttonsHbox,'String','Close','CallBack',@onCloseButton,'Enable','Off','Tag','close_button','KeyPressFcn',@onKeyPressed);

        set(vbox,'heights',[-1,20,25,25]);
        
        % Save some data
        handles.lastpath = data.lastpath;
        handles.dataFilePath = data.dataFilePath;
        guidata(h,handles);
    end
    function updateInterface(h)
        handles = guidata(h);
        
        objFigs = get(0,'children');
        numberOfFigures = length(objFigs);
        
        if isempty(objFigs)
            state = 'Off';
            listFig = cell(1,3);
            listFig{1,2} = '';
            listFig{1,3} = '';
        else
            state = 'On';
            listFig = cell(numberOfFigures,3);
            nindex = 0; % number of unnumbered figure 
            for i = 1:numberOfFigures
                index = i - nindex; % number of numbered figure 
                objectFig = objFigs(index);
                nameFig = get(objectFig,'Name');
                idFig = get(objectFig,'Number');
                if ~isempty(idFig)
                    if isempty(nameFig)
                        nameFig = 'Untitled';
%                         set(objectFig,'Name',nameFig);
                    end
                    listFig{index,1} = idFig;
                    listFig{index,2} = nameFig;
                    if strcmp(nameFig, 'Untitled')
                        listFig{index,3} = ['Figure ' num2str(idFig)];
                    else
                        listFig{index,3} = ['Figure ' num2str(idFig) ': ' nameFig];
                    end
%                     createMenu = true;
%                     figChildren = get(objectFig, 'Children');
%                     for i = 1:length(figChildren)
%                         if isa(figChildren(i), 'matlab.ui.container.Menu')
%                             if strcmp(get(figChildren(i), 'Text'), 'Fgm')
%                                 createMenu = false;
%                                 break;
%                             end
%                         end
%                     end
%                     if createMenu && ~strcmp(get(objectFig, 'MenuBar'), 'none')
%                         uimenu(objectFig, 'Text', 'Fgm');
%                     end
                else
                    objFigs(index) = [];
                    nindex = nindex + 1;
                end
            end
            listFig = listFig(~all(cellfun(@isempty,listFig),2),:); % delete empty rows
            [listFig, sortedxIndexes] = sortrows(listFig);
            handles.figures = objFigs(sortedxIndexes);
        end
        
        % Enable or disable menu content
        set(handles.save_button,'Enable',state);
        set(handles.close_button,'Enable',state);
        set(handles.rename_button,'Enable',state);
        set(handles.context_menu.save_button,'Enable',state);
        set(handles.context_menu.close_button,'Enable',state);
        set(handles.context_menu.focus_button,'Enable',state);
        set(handles.context_menu.rename_button,'Enable',state);
        
        % Update the list of displayed figures
        set(handles.list_box,'String',listFig(:,3));
        
        % Update
        handles.listFigures = listFig;
        set(handles.editNames,'String',strjoin(nameSelectFigs(handles),';'));
        
        % Save
        guidata(h,handles);
    end

    % -- Helper subfunctions
    function dlgchoice = overwriteDialog(filename)
        screenSize = get(0,'ScreenSize');
        windowSize = [380,10+25+25+10];
        d = dialog('Name','This file already exists','Position', ceil([(screenSize(3:4)-windowSize)/2+[0,100],windowSize]));
        
        vbox = uix.VBox('Parent',d,'Padding',10,'Spacing',0);
            question = uicontrol('Parent',vbox,'Style','text','String',['Overwrite ''',filename,''' ?']);
            hbox = uix.HBox('Parent',vbox);
                uicontrol('Parent',hbox,'Style','PushButton','String','Yes','Callback',@diagCallback);
                uicontrol('Parent',hbox,'Style','PushButton','String','Yes to all','Callback',@diagCallback);
                uicontrol('Parent',hbox,'Style','PushButton','String','No','Callback',@diagCallback);
                uicontrol('Parent',hbox,'Style','PushButton','String','No to all','Callback',@diagCallback);
                uicontrol('Parent',hbox,'Style','PushButton','String','Cancel','Callback',@diagCallback);
            set(vbox,'Heights',[25,25]);
            
        if question.Extent(3) > windowSize(1)
            set(d,'Position',ceil([(screenSize(3:4)-[question.Extent(3)+20,windowSize(2)])/2,[question.Extent(3)+20,windowSize(2)]]))
        end
        
        dlgchoice = 'Cancel'; % Default value
        uiwait();    
        function diagCallback(hObject, ~)
            dlgchoice = get(hObject, 'String');
            uiresume();
            delete(gcf);
        end
        
    end
    function id = idSelectFigs(handles)
        % check if the number of all selected items is equal to or less than the number of digits currently open
        if ~all(size(handles.listFigures,1)>=get(handles.list_box,'Value'))
            set(handles.list_box,'Value',1);
        end
        % get selected figure ID
        id = cell2mat(handles.listFigures(get(handles.list_box,'Value'),1));
    end
    function names = nameSelectFigs(handles)
        % check if the number of all selected items is equal to or less than the number of digits currently open
        if ~all(size(handles.listFigures,1)>=get(handles.list_box,'Value'))
            set(handles.list_box,'Value',1);
        end
        % get selected figure names
        names = handles.listFigures(get(handles.list_box,'Value'),2);
    end
    function figs = objSelectFigs(handles)
        % check if the number of all selected items is equal to or less than the number of digits currently open
        if ~all(size(handles.listFigures,1)>=get(handles.list_box,'Value'))
            set(handles.list_box,'Value',1);
        end
        % get selected figure objects
        figs = handles.figures(get(handles.list_box,'Value'));
    end

    % -- Window callback functions
    function onKeyPressed(~,event)
        if strcmp(event.EventName,'KeyPress')
            key = event.Key;
            tag = event.Source.Tag;
            if strcmpi(key,'f5')
                onRefreshButton();
            elseif strcmpi(key, 'f') && ~strcmp(tag,'edit') 
                onFocusFigure();
            elseif (strcmpi(key,'delete') || strcmpi(key,'backspace')) && ~strcmp(tag,'edit')
                onCloseButton();
            elseif strcmpi(key, 'f2')
                onFocusRename();
            elseif strcmpi(key,'return') && strcmp(tag,'edit')
                pause(0.1); % make sure handles.editNames.String is updated
                onRenameButton();
            elseif length(event.Modifier) == 1 && strcmpi(event.Modifier{1}, 'control') && strcmpi(event.Key,'s')
                onSaveButton();
            end
        end
    end
    function onCloseFgm(~,~)
        try
            handles = guidata(gcbo);
            selectedFormats =  [...
                    handles.check_fig.Value,...
                    handles.check_eps.Value,...
                    handles.check_pdf.Value,...
                    handles.check_svg.Value,...
                    handles.check_png.Value];
            lastpath = handles.lastpath;
            save(handles.dataFilePath, 'selectedFormats', 'lastpath');
        catch
            warning('Sorry, we can''t save your GUI settings...');
        end
        delete(gcbo);
    end

    % -- Button callback functions
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
%                 uicontrol(handles.editNames);
            end
        end
    end
    function onSaveButton(~,~)
        handles = guidata(gcbo);
        idSelectedFigures = idSelectFigs(handles);
        nameSelectedFigures = nameSelectFigs(handles);
        objSelectedFigures = objSelectFigs(handles);
        numberOfSelectedFigs = length(idSelectedFigures);
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
        if isfield(handles,'lastpath')
            lastpath = handles.lastpath;
        else
            lastpath = pwd;
        end
        for i = 1:numberOfSelectedFigs
            if strcmp(nameSelectedFigures(i), 'Untitled')
                nameSelectedFigures{i} = ['Figure_' num2str(idSelectedFigures(i))];
            end
        end
        if numberOfSelectedFigs==1
            if length(formats) > 1
                [file,path] = uiputfile('*.*','FigManager',fullfile(lastpath,char(nameSelectedFigures(1))));
            else
                [file,path] = uiputfile(ext,'FigManager',fullfile(lastpath,char(nameSelectedFigures(1))));
            end
            if all(path~=0)
                [~,namefile,~] = fileparts(file);
                nameSelectedFigures{1} = namefile;
            end
        else
            path = uigetdir(lastpath,'FigManager');
        end
        if all(path~=0)
            wb = waitbar(0,'');
            set(wb.Children.Title, 'Interpreter', 'none');
            dlgchoice = 'Yes';
            for i = 1:numberOfSelectedFigs
                for j = 1:length(formats)
                    extension = char(ext(j));
                    extension = extension(2:end);
                    wbInd = sub2ind([length(formats),numberOfSelectedFigs],j,i);
                    wbText = ['Saving : ' nameSelectedFigures{i} extension];
                    fullFilePath = fullfile(path,char(nameSelectedFigures(i)));
                    
                    if ~strcmpi(dlgchoice, 'Cancel')
                        waitbar((wbInd-1)/(length(formats)*numberOfSelectedFigs),wb,wbText);
                        if isfile([fullFilePath,extension]) % if the file already exists
                            fileAlreadyExist = true;
                            if (numberOfSelectedFigs > 1 || length(formats) > 1) && (strcmpi(dlgchoice, 'Yes') || strcmpi(dlgchoice, 'No'))
                                dlgchoice = overwriteDialog([fullFilePath,extension]);
                            end
                        else
                            fileAlreadyExist = false; % save if the file does not exist
                        end

                        if (strcmpi(dlgchoice, 'Yes') || strcmpi(dlgchoice, 'Yes to all')) || ~fileAlreadyExist
                            currentFig = objSelectedFigures(i);
                            if strcmp(char(formats(j)),'pdf')
                                currentFig.PaperPositionMode = 'auto';
                                currentFig.PaperUnits = 'points';
                                currentFig.PaperSize = [currentFig.PaperPosition(3)+1 currentFig.PaperPosition(4)+1];
                            end
                            saveas(currentFig,fullFilePath,char(formats(j)));
                            waitbar((wbInd+1)/(length(formats)*numberOfSelectedFigs),wb,wbText);
                        end
                    end
                end
            end
            close(wb);
            handles.selectedFormats = formats;
            handles.lastpath = path;
            guidata(gcbo, handles);
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
            if strcmp(newNames{index}, 'Untitled')
                set(figure(idSelectedFigures(index)),'Name','');
            else
                set(figure(idSelectedFigures(index)),'Name',newNames{index});
            end
        end
        updateInterface(gcbo);
    end
    function onRefreshButton(~,~)
        handles = guidata(gcbo);
        set(handles.list_box,'Value',1);
        updateInterface(gcbo);
    end

    % -- Context menu callback functions
    function onFocusCtxtmenuButton(~,~)
        handles = guidata(gcbo);
        idSelectedFigures = idSelectFigs(handles);
        for i = 1:length(idSelectedFigures)
            figure(idSelectedFigures(i));
        end
    end
    function onRenameCtxtmenuButton(~,~)
        handles = guidata(gcbo);
        uicontrol(handles.editNames);
    end
end