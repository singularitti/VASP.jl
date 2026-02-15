using FileTrees: FileTree, filter, path

export walk_workdirs

function walk_workdirs(root)
    tree = FileTree(root)
    return filter(tree; dirs=true) do node
        # Must compare the node to the tree itself, otherwise we will exclude the root directory
        node isa FileTree && (node === tree || isvalid(WorkDir(path(node))))
    end
end
