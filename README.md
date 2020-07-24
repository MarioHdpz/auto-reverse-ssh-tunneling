# Auto Reverse SSH tunneling

## Prerequisites

1. Have a properly configured VPS to accept ssh tunnels:
    - Incoming ports opened
    - Connection via a `.pem` key

1. Have a sudo user.

## How to use

1. Copy the `open-reverse-tunnel.sh` to the device where you want to open a reverse tunnel.

1. Give permissions as an executable script.

    ```console
    chmod +x open-reverse-tunnel.sh
    ```

1. Run the script:

    ```console
    ./open-reverse-tunnel.sh -k myKey.pem -p 1234 -u remoteuser -h example.com
    ```

    Where:
    - **k** is the path to the `.pem` file.
    - **p** is the VPS port for the reverse tunnel.
    - **u** is the VPS user.
    - **h** is the VPS host.
