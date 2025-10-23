#!/bin/bash 

# modifies setup.py

# https://computingforgeeks.com/how-to-install-python-on-ubuntu-linux-system/
version=3.12.7
for version in 3.12.7
do
  #echo cp ../transfer/Python-${version}_setup.py Python-${version}_setup.modified.py
  tarfile=Python-$version.tgz
  echo wget --no-clobber --quiet https://www.python.org/ftp/python/$version/$tarfile
  outputfile=Python-$version/setup.py
  echo tar --overwrite -xvf $tarfile $outputfile
  original=Python-${version}_setup.original.py
  modified=Python-${version}_setup.modified.py
  echo mv $outputfile $original
  echo "diff $original $modified > diff.$version"
  echo rmdir Python-$version 2\> /dev/null
done

- in detect_sqlite, drop the paths with /usr/local and add  /opt/tbio/domino_2022XX/include
- in configure_compiler, replace /usr/local with /opt/...

Python-3.10.2_setup.original.py

    def detect_sqlite(self):
        ...
        sqlite_inc_paths = [ '/usr/include',
                             '/usr/include/sqlite',
                             '/usr/include/sqlite3',
                             '/usr/local/include',
                             '/usr/local/include/sqlite',
                             '/usr/local/include/sqlite3',

    def configure_compiler(self):
           ...
        if not CROSS_COMPILING:
            add_dir_to_list(self.compiler.library_dirs, '/usr/local/lib')
            add_dir_to_list(self.compiler.include_dirs, '/usr/local/include')

Python-3.10.2_setup.modified.py

        sqlite_inc_paths = [ '/usr/include',
                             '/usr/include/sqlite',
                             '/usr/include/sqlite3',
                             '/opt/tbio/domino_202206/include',
                             ]
    
     def configure_compiler(self):
        ...
        if not CROSS_COMPILING:
            add_dir_to_list(self.compiler.library_dirs, '/opt/tbio/domino_202206/lib')
            add_dir_to_list(self.compiler.include_dirs, '/opt/tbio/domino_202206/include')
