# GIT Diff Notification Service for GitLab

Notifies on changes for given git repository files or folders with git-diff to given email adresses as HTML email.

## Features

- Supports multiple files
- Supports multiple folders
- Support for wildcards in filenames or folders

## Getting Started

These instructions will get you a copy of the project up and running on your own GitLab instance.

### Installing

Switch to your GitLab project settings and add these variables to the **Secret Variables** section of the **CI/CD Pipelines** options page.

 - SMTP_HOST = `smtp.example.com`
 - SMTP_USER = `me@example.com`
 - SMTP_PASS = `Pa$$w0rd`

#### Example

![screen-1](media/screen-1.png)

Now, add this snippet to your repositories `.gitlab-ci.yml` file as another task

```
diff_notification:
  stage: build
  image: pacecar/docker-diff-notification-service:0.2
  only:
    - master
  script:
    - ruby /ci-git-diff-notification-service.rb -f db/schema.rb,docs/api* -m me@example.com,them@example.com
    - ruby /ci-git-diff-notification-service.rb -f core/file.py -m alert@example.com
```

## Screenshot

![screen-2](media/screen-2.png)

## Built With

* [aha - Ansi HTML Adapter](https://github.com/theZiz/aha)

## License

All files are subjects to the LGPL2+ or the MPL1.1 (Dual licensed).