#! /bin/sh

# edit for latest version numbers:
file=file_cmds-272
libutil=libutil-51
libinfo=Libinfo-517
shell=shell_cmds-203

# Cleanup:
rm -rf file_cmds shell_cmds libutil libinfo
rm -rf $file $libutil $libinfo $shell

# get source for file_cmds
curl https://opensource.apple.com/tarballs/file_cmds/$file.tar.gz -O
tar xfz $file.tar.gz
rm $file.tar.gz
# move to position independent of version number
# so Xcode project stays valid
mv $file file_cmds 
(cd file_cmds ; patch -p1 < ../file_cmds.patch ; cd ..)

# get source for libutil:
curl https://opensource.apple.com/tarballs/libutil/$libutil.tar.gz -O
tar xfz $libutil.tar.gz
rm $libutil.tar.gz
mv $libutil libutil

# get source for libInfo:
curl https://opensource.apple.com/tarballs/Libinfo/$libinfo.tar.gz -O
tar xfz $libinfo.tar.gz
rm $libinfo.tar.gz 
mv $libinfo libinfo

# get source for shell_cmds:
curl https://opensource.apple.com/tarballs/shell_cmds/$shell.tar.gz -O
tar xfz $shell.tar.gz
rm $shell.tar.gz
mv $shell shell_cmds
(cd shell_cmds ; patch -p1 < ../shell_cmds.patch ; cd ..)




