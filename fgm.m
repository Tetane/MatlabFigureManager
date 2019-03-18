function fgm()
    % FGM - FigManager
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
        
        menu_listbox = uicontextmenu('Parent', h);
        handles.context_menu.save_button = uimenu(menu_listbox, 'Text', 'Save', 'CallBack', @onSaveButton, 'Enable', 'Off');
        handles.context_menu.close_button = uimenu(menu_listbox, 'Text', 'Close (del)', 'CallBack', @onCloseButton, 'Enable', 'Off');
        handles.context_menu.focus_button = uimenu(menu_listbox, 'Text', 'Focus (f)', 'CallBack', @onFocusFigure,'Enable', 'Off');
        handles.context_menu.rename_button = uimenu(menu_listbox, 'Text', 'Rename (f2)','CallBack', @onFocusRename, 'Enable', 'Off');
        
        set(handles.list_box, 'UiContextMenu', menu_listbox);
        
        guidata(h,handles);
    end
    function dlgchoice = overwriteDialog(filename)
        screenSize = get(0,'ScreenSize');
        windowSize = [380, 10+25+25+10];
        d = dialog('Name', 'This file already exists', 'Position', ceil([(screenSize(3:4)-windowSize)/2 + [0 100], windowSize]));
        
        vbox = uix.VBox('Parent', d, 'Padding', 10, 'Spacing', 0);
            question = uicontrol('Parent', vbox, 'Style', 'text', 'String', ['Overwrite '' ' filename ' '' ?']);
            hbox = uix.HBox('Parent', vbox);
                uicontrol('Parent', hbox, 'Style', 'PushButton', 'String', 'Yes','Callback', @diagCallback);
                uicontrol('Parent', hbox, 'Style', 'PushButton', 'String', 'Yes to all','Callback', @diagCallback);
                uicontrol('Parent', hbox, 'Style', 'PushButton', 'String', 'No','Callback', @diagCallback);
                uicontrol('Parent', hbox, 'Style', 'PushButton', 'String', 'No to all','Callback', @diagCallback);
                uicontrol('Parent', hbox, 'Style', 'PushButton', 'String', 'Cancel','Callback', @diagCallback);
            set(vbox, 'Heights', [25 25]);
            
        if question.Extent(3) > windowSize(1)
            set(d, 'Position', ceil([(screenSize(3:4)-[question.Extent(3) + 20, windowSize(2)])/2, [question.Extent(3) + 20, windowSize(2)]]))
        end
        
        dlgchoice = 'Cancel'; % Default value
        uiwait();    
        function diagCallback(hObject, ~)
            dlgchoice = get(hObject, 'String');
            uiresume();
            delete(gcf)
        end
        
    end
    function updateInterface(h)
        handles = guidata(h);
        
        figures = get(0,'children');
        newIndf = 0;
        for indf = 1: length(figures) % Remove figures without number
            if strcmpi(get(figures(indf-newIndf), 'IntegerHandle'), 'Off')
                figures(indf-newIndf) = [];
                newIndf = newIndf+1;
            end
        end
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
%                     set(objectFig,'Name',nameFig);
                end
                listFig{index,1} = idFig;
                listFig{index,2} = nameFig;
                if strcmp(nameFig, 'Untitled')
                    listFig{index,3} = ['Figure ' num2str(idFig)];
                else
                    listFig{index,3} = ['Figure ' num2str(idFig) ': ' nameFig];
                end
            end
            listFig = listFig(~all(cellfun(@isempty,listFig),2),:); % delete empty rows
            listFig = sortrows(listFig);
        end
        
        set(handles.save_button,'Enable',state);
        set(handles.close_button,'Enable',state);
        set(handles.rename_button,'Enable',state);
        set(handles.context_menu.save_button ,'Enable',state);
        set(handles.context_menu.close_button ,'Enable',state);
        set(handles.context_menu.focus_button, 'Enable',state);
        set(handles.context_menu.rename_button, 'Enable',state);
        
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
    function fig = getFigure(id)
        figures = get(0,'Children');
        fig = nan;
        for num = 1:length(figures)
            if (figures(num).Number == id)
                fig = figures(num);
            end
        end
    end

    % -- Callback functions
    function onKeyPressed(~,eventdata)
%         handles = guidata(gcbo);
        if strcmp(eventdata.EventName,'KeyPress')
            key = eventdata.Key;
            tag = eventdata.Source.Tag;
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
        if isfield(handles,'lastpath')
            lastpath = handles.lastpath;
        else
            lastpath = pwd;
        end
        for i = 1:length(idSelectedFigures)
            if strcmp(nameSelectedFigures(i), 'Untitled')
                nameSelectedFigures{i} = ['Figure_' num2str(idSelectedFigures(i))];
            end
        end
        if length(idSelectedFigures)==1
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
            for i = 1:length(idSelectedFigures)
                for j = 1:length(formats)
                    extension = char(ext(j));
                    extension = extension(2:end);
                    wbInd = sub2ind([length(formats),length(idSelectedFigures)],j,i);
                    wbText = ['Saving : ' nameSelectedFigures{i} extension];
                    fullFilePath = fullfile(path,char(nameSelectedFigures(i)));
                    
                    if ~strcmpi(dlgchoice, 'Cancel')
                        waitbar((wbInd-1)/(length(formats)*length(idSelectedFigures)),wb,wbText);
                        if isfile([fullFilePath,extension]) % if the file already exists
                            fileAlreadyExist = true;
                            if (length(idSelectedFigures) > 1 || length(formats) > 1) && (strcmpi(dlgchoice, 'Yes') || strcmpi(dlgchoice, 'No'))
                                dlgchoice = overwriteDialog([fullFilePath,extension]);
                            end
                        else
                            fileAlreadyExist = false; % save if the file does not exist
                        end

                        if (strcmpi(dlgchoice, 'Yes') || strcmpi(dlgchoice, 'Yes to all')) || ~fileAlreadyExist
                            currentFig = figure(idSelectedFigures(i));
                            if strcmp(char(formats(j)),'pdf')
                                currentFig.PaperPositionMode = 'auto';
                                currentFig.PaperUnits = 'points';
                                currentFig.PaperSize = [currentFig.PaperPosition(3)+1 currentFig.PaperPosition(4)+1];
                            end
                            saveas(currentFig,fullFilePath,char(formats(j)));
                            waitbar((wbInd+1)/(length(formats)*length(idSelectedFigures)),wb,wbText);
                        end
                    end
                end
            end
            close(wb);
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
    function onFocusFigure(~,~)
        handles = guidata(gcbo);
        idSelectedFigures = idSelectFigs(handles);
        for i = 1:length(idSelectedFigures)
            figure(idSelectedFigures(i));
        end
    end
    function onFocusRename(~,~)
        handles = guidata(gcbo);
        uicontrol(handles.editNames);
    end
end