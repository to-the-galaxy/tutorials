# Git tutorial

Commands list:

```bash
# Status
$ git status

# Stage changed files to be committed
$ git add --all
$ git add <file-name>

# Commit changes
$ git commit

# Make new branch and change to it
$ git checkout -b <branch-name>

# Change branch
$ git checkout <branch-name>

# List branches
$ git branch

# Merge branch to master
$ git checkout master
$ git merge <branch-to-be-merged>

# Delete branch
$ git branch -d <branch-to-be-deleted>

# Log
$ git log

# Log details of last <number-of-commits>
$ git log -p -<number-of-commits>

# Log in pretty format
$ git log --pretty=oneline
$ git log --pretty=format:"%h - %ar : %s"
$ git log --pretty=format:"%h - %an, %ar : %s"
```

