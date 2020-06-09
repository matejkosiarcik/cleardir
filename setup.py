import os
from setuptools import setup


def read(filepath):
    with open(os.path.join(os.path.dirname(__file__), filepath)) as file:
        return file.read()


setup(
    name='cleardir',
    version='0.1.0', # TODO: get dynamically
    description='Directory cleaner from development and OS junk files',
    long_description=read('README.md'),
    long_description_content_type='text/markdown',
    license='MIT',
    keywords='filesystem files',

    author='Matej Kosiarcik',
    author_email='matej.kosiarcik@gmail.com',
    maintainer='Matej Kosiarcik',
    maintainer_email='matej.kosiarcik@gmail.com',

    url='https://github.com/matejkosiarcik/cleardir',
    download_url='https://github.com/matejkosiarcik/cleardir/releases',

    packages=['cleardir'],
    entry_points={
        'console_scripts': ['cleardir = cleardir:main'],
    },

    # TODO: check on python 2.6, 2.7
    # TODO: check other python 3 versions
    python_requires='>=3, !=3.0.*, !=3.1.*, !=3.2.*, !=3.3.*, !=3.4.*, <4',
    requires=[],

    classifiers=[
        'Development Status :: 3 - Alpha',

        'Environment :: Console',
        'Intended Audience :: End Users/Desktop',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',

        # TODO: verify windows
        # 'Operating System :: OS Independent',
        'Operating System :: MacOS',
        'Operating System :: MacOS :: MacOS X',
        # 'Operating System :: Microsoft :: Windows',
        # 'Operating System :: Microsoft :: Windows :: Windows 10',
        # 'Operating System :: Other OS',
        'Operating System :: POSIX',
        'Operating System :: POSIX :: BSD',
        'Operating System :: POSIX :: Linux',
        'Operating System :: POSIX :: Other',
        'Operating System :: Unix',

        # 'Programming Language :: Python :: 2'
        # 'Programming Language :: Python :: 2.6',  # TODO: check
        # 'Programming Language :: Python :: 2.7'
        'Programming Language :: Python :: 3',
        # 'Programming Language :: Python :: 3.1',
        # 'Programming Language :: Python :: 3.2',
        # 'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python',

        # 'Topic :: Software Development',
        # 'Topic :: System :: Archiving',
        # 'Topic :: System :: Filesystems',
        # 'Topic :: System',
        'Topic :: Utilities',
    ]
)
