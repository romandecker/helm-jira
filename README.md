helm-jira
=========

Issues and Pull requests at your fingertips through [helm](https://github.com/emacs-helm/helm).

## Installation

helm-jira should be available on [melpa](https://melpa.org/) and can
be installed from there.

### Installation via `use-package`

``` emacs-lisp
(use-package helm-jira
  :config

  (setq
   ;; URL of your JIRA instance (should not end in a slash)
   helm-jira/url "https://jira.yourcompany.com"      

   ;; The ID of the board you want to interact with
   helm-jira/board-id 123

   ;; The username to use to log in to JIRA
   helm-jira/username "myJiraUser"

   ;; The JIRA-project you want to interact with
   helm-jira/project "myProject"


   ;; URL of the stash/bitbucket API (should not end in a slash)
   helm-jira/stash-url "https://src.yourcompany.com"

   ;; The stash/bitbucket repo you want to interact with
   helm-jira/repo "myRepo"))
```

### Configuration

There's a few custom variables you may want to set:

* `helm-jira/url`: 
* `helm-jira/board-id`: The ID of the board you want to interact with
* `helm-jira/username`: The username to use to log in to JIRA
* `helm-jira/project`: The JIRA-project you want to interact with
* `helm-jira/stash-url`: URL of the stash/bitbucket API (should not end in a slash)
* `helm-jira/repo`: The stash/bitbucket repo you want to interact with


### Commands

Here's the commands that `helm-jira` currently provides:

* `helm-jira/helm-issues`: Use `helm` to browse through the issues on
  the configured board. The default action will check-out a respective
  PR for the issue using `magit`. You can also open your browser to
  browse to the selected issue.
* `helm-jira/helm-pull-requests`: Use `helm` to browse through the
  currently open Pull Requests on stash/BitBucket. Default action will
  check-out an according branch using `magit` (magit needs to know
  about it, so you might want to run `magit-fetch` first). You can
  also open your browser to browse to the selected PR.
* `helm-jira/logout`: Unset the stored password, you will be asked for your password on the next `helm-jira` command.
