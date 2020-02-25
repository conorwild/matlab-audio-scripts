function createDirectory(name, goto)

    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    mkdir(name);
    
    if goto
        cd(name);
    end
    
    warning('on', 'MATLAB:MKDIR:DirectoryExists');

end