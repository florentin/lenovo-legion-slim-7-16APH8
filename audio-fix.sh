# Run the following commands one by one

mkdir custom_kernel && cd "$_"

## Fedora instructions
## https://docs.fedoraproject.org/en-US/quick-docs/kernel-build-custom/

## fedpkg
## https://docs.fedoraproject.org/en-US/package-maintainers/Package_Maintenance_Guide/

sudo dnf install fedpkg

fedpkg clone -a kernel # you might need to retry this cmd

## Alternative: git clone https://src.fedoraproject.org/rpms/kernel.git

cd kernel
sudo dnf builddep kernel.spec
sudo dnf install qt3-devel libXi-devel gcc-c++

sudo usermod -a -G pesign $USER
sudo /usr/libexec/pesign/pesign-authorize
cd ../ # back to custom_kernel

## I could not figure out how to build a signed kernel, someone maybe figure out how to fix these instructions
## We'll sign the kernel later, after installation
mkdir ./keys && cd "$_"

openssl req -new -x509 -newkey rsa:2048 -keyout "key.pem" \
        -outform DER -out "cert.der" -nodes -days 36500 \
        -subj "/CN=Secure Boot Signing Key/"

## You will be asked to authorize the import at next boot.
sudo mokutil --import "cert.der"

## After reboot, test key
sudo mokutil --test-key "cert.der"

## You will be asked for a password, remember it
openssl pkcs12 -export -out key.p12 -inkey key.pem -in cert.der

export name=$(hostname)

sudo certutil -A -i cert.der -n "$name" -d /etc/pki/pesign/ -t "Pu,Pu,Pu"
sudo pk12util -i key.p12 -d /etc/pki/pesign

sudo dnf install ccache

cd ../ # back to custom_kernel

## clone upstream kernel
git clone https://github.com/torvalds/linux.git

## OPTIONAL steps
## The audio drivers from HEAD might not work so get the files from this commit: 9d1694dc91ce7b80bc96d6d8eaf1a1eca668d847
cd linux
git checkout 9d1694dc91ce7b80bc96d6d8eaf1a1eca668d847 # we're now in a detached HEAD
cd ../ # back to custom_kernel


cd kernel
## Check your Fedora version `cat /etc/fedora-release`

git switch f39

## Download the kernel sources
fedpkg sources

## This will extract the sources
fedpkg prep

cp -r kernel-6.6.12/linux-6.6.12-200.fc39.x86_64 kernel-6.6.12/linux-6.6.12-200.fc39.x86_64-patched

cd ../ # back to custom_kernel

## Prepare the patch file linux-kernel-test.patch

SOURCE=$(pwd)/linux # upstream kernel files
DEST=$(pwd)/kernel/kernel-6.6.12/linux-6.6.12-200.fc39.x86_64-patched # fedora kernel sources

[ -d "$SOURCE" ] && echo SOURCE ok
[ -d "$DEST" ] && echo DEST ok

files=(
include/sound/cs35l41*:include/sound/
sound/pci/hda/cirrus*:sound/pci/hda/
sound/pci/hda/cs35l41*:sound/pci/hda/
sound/pci/hda/patch_realtek.c:sound/pci/hda/
sound/soc/codecs/cs35l41*:sound/soc/codecs/
Documentation/devicetree/bindings/sound/cirrus,cs35l41.yaml:Documentation/devicetree/bindings/sound/
sound/pci/hda/Makefile:sound/pci/hda/
)

OLDIFS=$IFS; IFS=':';
for f in "${files[@]}"; do
    set -- $f;
    echo copy $1 to $2;
    cp $SOURCE/$1 $DEST/$2
done
IFS=$OLDIFS

cd kernel/kernel-6.6.12/
## Generate the patch
diff -rupN linux-6.6.12-200.fc39.x86_64 linux-6.6.12-200.fc39.x86_64-patched > ../linux-kernel-test.patch 
cd ../ # in kernel

## Now you have the patch with the latest audio drivers
cat linux-kernel-test.patch

## To avoid conflicts with existing kernels, you can set a custom buildid by changing # define buildid .local to %define buildid .<your_custom_id_here> in kernel.spec.
sed -i "s/# define buildid .local/%define buildid .$name/g" kernel.spec

## Once the certificate and key are imported into your nss database, you can build the kernel with the selected key by adding %define pe_signing_cert <MOK certificate nickname> to the kernel.spec file or calling rpmbuild directly with the --define "pe_signing_cert <MOK certificate nickname>" flag.
sed -i "s/.$name/.$name\n%define pe_signing_cert $name/g" kernel.spec


## Test the patch
fedpkg prep

## Build
fedpkg local

## Install new kernel
sudo dnf install \
    ./kernel/x86_64/kernel-6.6.12-200.fc39.x86_64.rpm \
    ./kernel/x86_64/kernel-core-6.6.12-200.fc39.x86_64.rpm \
    ./kernel/x86_64/kernel-modules-6.6.12-200.fc39.x86_64.rpm \
    ./kernel/x86_64/kernel-modules-core-6.6.12-200.fc39.x86_64.rpm \
    ./kernel/x86_64/kernel-modules-extra-6.6.12-200.fc39.x86_64.rpm

## Sign the new kernel
cd keys
openssl x509 -in cert.der -inform DER -out cert.pem -outform PEM

sbsign /boot/vmlinuz-6.6.12-200.fc39.x86_64 \
    --key key.pem --cert cert.pem \
    --output /boot/vmlinuz-6.6.12-200.fc39.x86_64