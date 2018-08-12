!/bin/bash

VOLUME_ID=""
MOUNT_POINT=""
DEVICE=""
VOLUME_TYPE=""
PARTITION=""
FSTAB="false"
INSTANCE_ID=""
LATEST_SNAPSHOT=""
CHECK_VOLUME_MAX_COUNT=30
INSTALLED="true"

function mount_device() {
        echo "create moount point $MOUNT_POINT"
        mkdir -p $MOUNT_POINT

        echo "attaching volume"
        aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device $DEVICE --region ap-southeast-2
        NEXT_WAIT_TIME=0
        echo "format disk = $INSTALLED"
        if [ "$INSTALLED" = "false" ]; then
          echo "mkfs -t ext4 /dev/xvdf"

          until mkfs -t ext4 /dev/xvdf || [ $NEXT_WAIT_TIME -eq 20 ]; do
          sleep $(( NEXT_WAIT_TIME++ ))
          done
        fi

        echo "mount -t $VOLUME_TYPE"
        echo "==========================="
        echo "$(mount)"
        echo "==========================="
        echo "$(lsblk)"
        echo "==========================="
        NEXT_WAIT_TIME=0
                echo "mount -t $VOLUME_TYPE $PARTITION $MOUNT_POINT || [ $NEXT_WAIT_TIME -eq 20 ]; do"
        until mount -t $VOLUME_TYPE $PARTITION $MOUNT_POINT || [ $NEXT_WAIT_TIME -eq 20 ]; do
        sleep $(( NEXT_WAIT_TIME++ ))
        done

        if [ "$FSTAB" == "true" ]; then
            echo "$PARTITION $MOUNT_POINT $VOLUME_TYPE defaults 0 2" >> /etc/fstab
        fi

        if [ "$INSTALLED" = "false" ]; then
            sudo mkdir -p /data/html
            sudo mkdir -p /data/mysql
        fi
        aws ssm put-parameter --name "/blakey/wordpress/installed" --value "true" --type String --overwrite --region ap-southeast-2
}

function check_volume() {

        vol_status=$(aws ec2 describe-volumes --region ap-southeast-2  --volume-ids $VOLUME_ID | jq -r .Volumes[0].State)
        echo $vol_status
        output=$(echo $vol_status | grep "available" )
        status=$?
        count=$CHECK_VOLUME_MAX_COUNT

        while [ $status -ne 0 -a $count -ne 0 ]
        do
                sleep 10
                vol_status=$(aws ec2 describe-volumes --region ap-southeast-2  --volume-ids $VOLUME_ID | jq -r .Volumes[0].State)
                echo $vol_status
                output=$(echo $vol_status | grep "available" )
                status=$?

                count=$(($count - 1))

        done
               if [ $status -ne 0 ]; then
                # timeout and still not available
          quit_with_error "The Volume $VOLUME_ID is not available after $CHECK_VOLUME_MAX_COUNT*10"
        fi

}


function setup() {
        while getopts "v:m:i:d:t:p:fs" OPTION; do
                case $OPTION in
                        v)
                                VOLUME_ID=$OPTARG
                                ;;
                        m)
                                MOUNT_POINT=$OPTARG
                                ;;
                        i)      INSTALLED=$OPTARG
                                ;;
                        d)
                                DEVICE=$OPTARG
                                ;;
                        t)
                                VOLUME_TYPE=$OPTARG
                                ;;
                        p)
                                PARTITION=$OPTARG
                                ;;
                        f)
                                FSTAB="true"
                                ;;
                        s)
                               LATEST_SNAPSHOT="true"
                                ;;
                        *)
                                quit_with_error "Unimplemented option $OPTION chosen."
                                ;;
                esac
        done

        if [ -z "$PARTITION" ]; then
                PARTITION=$DEVICE
        fi

        INSTANCE_ID=$(curl -s 169.254.169.254/2014-02-25/meta-data/instance-id)

        log "(VOLUME_ID: $VOLUME_ID, MOUNT_POINT: $MOUNT_POINT, INSTALLED: $INSTALLED, DEVICE: $DEVICE, PARTITION: $PARTITION, VOLUME_TYPE: $VOLUME_TYPE, FSTAB: $FSTAB, LATEST_SNAPSHOT: $LATEST_SNAPSHOT)"
}

function quit_with_error() {
        log $1
        exit 1
}

function log() {
        echo "$*"
}


function main() {
        echo "setup"
        setup $*
        echo "check_volume"
        check_volume
        echo "mount_devie"
        mount_device
}

main $*