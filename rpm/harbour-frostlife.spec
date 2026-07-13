Name:       harbour-frostlife
Summary:    Frostlife — life counter for Magic: The Gathering (EDH)
Version:    0.1.0
Release:    1
License:    MIT
URL:        https://github.com/nib333/Frostlife
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   libsailfishapp-launcher
Requires:   nemo-qml-plugin-configuration-qt5
BuildRequires: pkgconfig(sailfishapp) >= 1.0.2
BuildRequires: desktop-file-utils

%description
Frostlife — a dark-first, EDH-focused life counter for Magic: The
Gathering.
Tracks life, commander damage (with partner support), poison and
other counters, monarch and initiative, with undo and autosave.
Designed for the Jolla Phone AMOLED display.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install
desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
