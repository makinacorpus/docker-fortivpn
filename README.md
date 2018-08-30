# docker-fortivpn-socks5 [![Docker Build Status](https://img.shields.io/docker/build/makinacorpus/docker-fortivpn.svg)](https://hub.docker.com/r/makinacorpus/docker-fortivpn/builds/)

- Connect to a Fortinet SSL-VPN via http/socks5 proxy.
- Largerly inspired from [this image](https://github.com/Tosainu/docker-fortivpn-socks5) (credits)

## Usage

1. Create a openfortivpn configuration file.

    ```
    $ cat /path/to/config
    host = vpn.example.com
    port = 443
    username = foo
    password = bar
    ```

2. Run following command to start the container.

    ```
    $ docker container run \
        --cap-add=NET_ADMIN \
        --device=/dev/ppp \
        --rm \
        -v /path/to/config:/etc/openfortivpn/config:ro \
        myon/fortivpn-socks5
    ```

3. Now you can use SSL-VPN via `http://<container-ip>:8443` or `socks5://<container-ip>:8443`.

    ```
    $ http_proxy=http://172.17.0.2:8443 curl http://example.com

    $ ssh -o ProxyCommand="nc -x 172.17.0.2:8443 %h %p" foo@example.com
    ```


4. Altertavily you may have a look to the entrypoint and the compose files to use with a SSH tunnel (in order to use a bastion host)

## License

[MIT](https://github.com/Tosainu/docker-fortivpn-socks5/blob/master/LICENSE)
