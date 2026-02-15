using FileTrees: FileTree, filter, path, name

export walk_workdirs, list_files

function walk_workdirs(root)
    tree = FileTree(root)
    return filter(tree; dirs=true) do node
        # Must compare the node to the tree itself, otherwise we will exclude the root directory
        node isa FileTree ? (node == tree || isvalid(WorkDir(path(node)))) : true
    end
end

function list_files(tree::FileTree, pattern)
    return filter(tree; dirs=false) do node
        node isa FileTree ? false : pattern == name(node)
    end
end
