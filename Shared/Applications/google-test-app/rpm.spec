Name:           %{_name}
Version:        %{_version}
Release:        %{_release}
Summary:        %{_summary}

License:        %{_license}
URL:            %{_url}
Source0:        %{_source}

#BuildRequires:  cmake, gcc, g++
#Requires:       cmake, gcc, g++

%description
Google Test is a C++ testing framework for writing and running C++ tests.

%prep
%setup -q

%build
mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=%{_prefix}
make -j$(nproc)

%install
cd build
make install DESTDIR=%{buildroot}

%global lib_dir usr/lib/aarch64-linux-gnu
%global include_dir usr/include

%files
%license LICENSE
/%{lib_dir}/*
/%{include_dir}/*


%changelog
* %{_build_date} Your Name <you@example.com> - 1.14.0-1
- Initial RPM release of Google Test
