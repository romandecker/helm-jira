;;; helm-jira.el --- Helm bindings for JIRA/Bitbucket/stash -*- lexical-binding: t -*-

;; Author: Roman Decker <roman dot decker at gmail dot com>
;; URL: https://github.com/DeX3/general.el
;; Created: July 19, 2018
;; Keywords: helm, jira, bitbucket, stash
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5") (helm "1.9.9"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; For more information see the README in the online repository.

;;; Code:

(defgroup helm-jira nil
  "helm-jira customization group."
  :group 'applications)

(defcustom helm-jira/url nil
  "JIRA url to use, should include protocol and not end in a slash."
  :group 'helm-jira
  :type 'string)

(defcustom helm-jira/stash-url nil
  "Stash url to use (for bitbucket API, should include protocol and not end in a slash)."
  :group 'helm-jira
  :type 'string
  :initialize 'custom-initialize-set)

(defcustom helm-jira/board-id nil
  "ID of the JIRA-board you want to work with."
  :group 'helm-jira
  :type 'integer
  :initialize 'custom-initialize-set)

(defcustom helm-jira/username nil
  "Username to use when logging in to JIRA."
  :group 'helm-hira
  :type 'integer
  :initialize 'custom-initialize-set)

(defcustom helm-jira/password nil
  "Password to use when logging in to JIRA.  Not recommended to set this (helm-jira will save password per session)."
  :group 'helm-jira
  :type 'string
  :initialize 'custom-initialize-set)

(defcustom helm-jira/project nil
  "The JIRA project to use for bitbucket API requests."
  :group 'helm-jira
  :type 'string
  :initialize 'custom-initialize-set)

(defcustom helm-jira/repo nil
  "The BitBucket repo to use for bitbucket API requests."
  :group 'helm-jira
  :type 'string
  :initialize 'custom-initialize-set)

(defun helm-jira/build-basic-auth-token ()
  "Build the base64-encoded auth token from `helm-jira/username' and `helm-jira/password'."
  (base64-encode-string (format "%s:%s" helm-jira/username helm-jira/password)))

(defun helm-jira/build-auth-header ()
  "Build the Authorization-Header for JIRA requests."
  (format "Basic %s" (helm-jira/build-basic-auth-token)))

(defun helm-jira/ensure-password ()
  "Ensures that `helm-jira/password' is set."
  (when (not helm-jira/password)
    (helm-jira/read-password)))

(defun helm-jira/read-password ()
  "Read a new value for `helm-jira/password'."
  (setq helm-jira/password (read-passwd (format "JIRA-Password for %s: " helm-jira/username)))
  nil)

(defun helm-jira/logout ()
  "Unset `helm-jira/password'."
  (interactive)
  (setq helm-jira/password nil)
  (message "Cleared JIRA password"))

(defun helm-jira/request (&rest args)
  "Call `request' with the supplied `ARGS', but ensure that a password is set and credentials are supplied."
  (helm-jira/ensure-password)
  (apply 'request (append args
                          `(:headers (("Authorization" . ,(helm-jira/build-auth-header)))))))

(defun helm-jira/fetch-issues (callback)
  "Fetch all open issues for the configured board and call `CALLBACK' with the resulting list."
  (helm-jira/request
   (format "%s/rest/agile/1.0/board/%s/issue" helm-jira/url helm-jira/board-id)
   :params '(("fields" . "summary")
             ("maxResults" . "200")
             ("jql" . "sprint in openSprints()"))
   :parser 'json-read
   :success (function*
             (lambda (&key data &allow-other-keys)
               (funcall callback (alist-get 'issues data))))))

(defun helm-jira/fetch-pull-requests (callback)
  "Fetch all open pull requests for the configured project and repo and call `CALLBACK' with the resulting list."
  (helm-jira/request
   (format "%s/rest/api/1.0/projects/%s/repos/%s/pull-requests" helm-jira/stash-url helm-jira/project helm-jira/repo)
   :parser 'json-read
   :success (function* (lambda (&key data &allow-other-keys)
                         (funcall callback (alist-get 'values data))))))

(defun helm-jira/fetch-issue-details (issue-id callback)
  "Fetch the details for a single issue by its `ISSUE-ID' (=purely numeric, not its key), and call `CALLBACK' with the resulting list of issues."
  (helm-jira/request
   (format "%s/rest/dev-status/latest/issue/detail" helm-jira/url)
   :params `(("issueId" . ,issue-id)
             ("applicationType" . "stash")
             ("dataType" . "pullrequest"))
   :parser 'json-read
   :success (function* (lambda (&key data &allow-other-keys)
                         (funcall callback (elt (alist-get 'detail data) 0))))))

(defun helm-jira/build-candidate-list-from-issues (issues)
  "Take `ISSUES' as returned by helm-jira/fetch-issues and build a suitable candidate list for helm with it."
  (mapcar
   (lambda (issue)
     (let* ((key (alist-get 'key issue))
            (fields (alist-get 'fields issue))
            (summary (alist-get 'summary fields)))
       `(,(format "%s: %s" key summary) . ,issue)))
   issues))


(defun helm-jira/build-candidate-list-from-pull-requests (pull-requests)
  "Take `PULL-REQUESTS' as returned by helm-jira/fetch-pull-requests and build a suitable candidate list for helm with it."
  (mapcar
   (lambda (pr)
     (let* ((title (alist-get 'title pr))
            (id (alist-get 'id pr))
            (author (alist-get 'user (alist-get 'author pr)))
            (author-name (alist-get 'displayName author)))
       `(,(format "%s: %s\t%s"
                  (propertize (format "#%s" id) 'font-lock-face 'font-lock-constant-face)
                  title
                  (propertize (concat "@" author-name) 'font-lock-face 'font-lock-comment-face)) . ,pr)))
   pull-requests))

(defun helm-jira/helm-issues ()
  "Fetch a list of issues from JIRA and prompt for selection of one."
  (interactive)
  (helm-jira/fetch-issues
   (lambda (issues)
     (let* ((helm-source
             (helm-build-sync-source "jira-issues-source"
               :candidates (helm-jira/build-candidate-list-from-issues issues)
               :action (helm-make-actions
                        "Check-out" #'helm-jira/helm-action-checkout-issue
                        "Open in browser" #'helm-jira/helm-action-open-issue-in-browser))))
       (helm :sources helm-source)))))

(defun helm-jira/helm-pull-requests ()
  "Fetch a list of pull-requests from Bitbucket and prompt for selection of one to open in the browser."
  (interactive)
  (helm-jira/fetch-pull-requests
   (lambda (pull-requests)
     (let* ((helm-source
             (helm-build-sync-source "jira-pull-requests-source"
               :candidates (helm-jira/build-candidate-list-from-pull-requests pull-requests)
               :action (helm-make-actions
                        "Check-out" #'helm-jira/helm-action-checkout-pull-request
                        "Open in browser" #'helm-jira/helm-action-open-pull-request-in-browser))))
       (helm :sources helm-source)))))

(defun helm-jira/magit-checkout-pull-request ()
  "Fetch a list of pull-requests from Bitbucket and prompt for selection of one to open in the browser."
  (interactive)
  (helm-jira/fetch-pull-requests
   (lambda (pull-requests)
     (let* ((helm-source
             (helm-build-sync-source "jira-pull-requests-source"
               :candidates (helm-jira/build-candidate-list-from-pull-requests pull-requests)
               :action (helm-make-actions "Check-out" #'helm-jira/helm-action-checkout-pull-request))))
       (helm :sources helm-source)))))


(defun helm-jira/helm-action-open-issue-in-browser (issue)
  "Open the given `ISSUE' in the browser."
  (let ((key (alist-get 'key issue)))
    (browse-url (format "%s/browse/%s" helm-jira/url key))))

(defun helm-jira/helm-action-open-pull-request-in-browser (pull-request)
  "Open the given `PULL-REQUEST' in the browser."
  (let* ((links (alist-get 'links pull-request))
         (self (elt (alist-get 'self links) 0))
         (href (alist-get 'href self)))
    (browse-url href)))

(defun helm-jira/helm-action-checkout-pull-request (pull-request)
  "Check-out the given `PULL-REQUEST' using magit (branch has to already exist currently)."
  (let* ((from-ref (alist-get 'fromRef pull-request))
         (display-id (alist-get 'displayId from-ref)))
    (magit-checkout display-id)))

(defun helm-jira/helm-action-checkout-issue (issue)
  "Check-out a branch for the given `ISSUE'."
  (let* ((id (alist-get 'id issue)))
    (helm-jira/fetch-issue-details id #'helm-jira/checkout-branch-for-issue-details)))

(defun helm-jira/checkout-branch-for-issue-details (issue-details)
  "Check-out the branch contained in the given `ISSUE-DETAILS' response."
  (let* ((branches (alist-get 'branches issue-details))
         (branch-count (length branches))
         (branch (if (= branch-count 1)
                     (elt branches 0)
                   (message "There are multiple branches for this issue, not yet implemented!")
                   (elt branches 0)))
         (branch-name (alist-get 'name branch)))
    (magit-checkout branch-name)))

(provide 'helm-jira)
;;; helm-jira.el ends here
