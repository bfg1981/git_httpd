Git httpd is an Apache webserver service that is designed to deploy directly from a Git repository using webhooks for automatic updates. This service is the most basic form but further functionality can be derived by hooking into the setup functionality for the webserver.

## Repository and image

- Source repository: [bfg1981/git_httpd](https://github.com/bfg1981/git_httpd)
- DockerHub image: [therealbfg/git_httpd](https://hub.docker.com/r/therealbfg/git_httpd)

## Environment variables

The container serves `/var/www/localhost/htdocs`. It can either use an already
mounted repository there, or initialize/manage the checkout itself.

| Variable | Purpose |
| --- | --- |
| `GIT_SOURCE` | Git URL to clone into `/var/www/localhost/htdocs`. When set, startup will clone on first run and `git pull` on later runs. |
| `FORCE_REINIT` | Set to a positive number to remove the existing webroot contents and clone `GIT_SOURCE` again. |
| `HOOKS` | Space-separated webhook endpoint names to expose through Apache. Defaults to `postreceive`. |
| `SECRET` | Optional GitHub webhook secret used by the webhook listener. |

Notes:

- If `GIT_SOURCE` is not set, the container assumes the repository is provided
  externally, for example as a mounted volume.
- Webhooks update the content checkout. Updating the container image itself is a
  separate deployment step.
