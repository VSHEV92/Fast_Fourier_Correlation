# ---------------------------------------------------------------------
# ----- Cкрипт для автоматической упаковки ядра из исходников ---------
# ---------------------------------------------------------------------
set Project_Name Fast_Fourier_Correlation_Project
set IP_Core_dir IP_Core 
close_project -quiet
if { [file exists $Project_Name] != 0 } { 
	file delete -force $Project_Name
}

if { [file exists $IP_Core_dir] != 0 } { 
	file delete -force IP
}

source ./tcl/create_project.tcl

# начинаем упаковку ядра
update_compile_order -fileset sources_1
ipx::package_project -root_dir $IP_Core_dir -vendor VSHEV92 -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $IP_Core_dir/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $IP_Core_dir $IP_Core_dir/component.xml

set_property display_name Fast_Fourier_Correlation [ipx::current_core]
set_property description Fast_Fourier_Correlation [ipx::current_core]

# устанавливаем совместимость со всеми кристалами
set_property supported_families {artix7 Production artix7 Beta artix7l Beta qartix7 Beta qkintex7 Beta qkintex7l Beta kintexu Beta kintexuplus Beta qvirtex7 Beta virtexuplus Beta qzynq Beta zynquplus Beta kintex7 Beta kintex7l Beta spartan7 Beta virtex7 Beta virtexu Beta virtexuplus58g Beta virtexuplusHBM Beta aartix7 Beta akintex7 Beta aspartan7 Beta azynq Beta zynq Beta} [ipx::current_core]

# -----------------------------------------------------------
# настройка NFFT
set_property display_name {NFFT} [ipgui::get_guiparamspec -name "NFFT" -component [ipx::current_core] ]
set_property tooltip {NFFT} [ipgui::get_guiparamspec -name "NFFT" -component [ipx::current_core] ]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "NFFT" -component [ipx::current_core] ]
set_property value 128 [ipx::get_user_parameters NFFT -of_objects [ipx::current_core]]
set_property value 128 [ipx::get_hdl_parameters NFFT -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters NFFT -of_objects [ipx::current_core]]
set_property value_validation_list {128 256 512 1024 2048 4096 8192} [ipx::get_user_parameters NFFT -of_objects [ipx::current_core]]

# пакуем ядро
update_compile_order -fileset sources_1
set_property core_revision 2 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete


# закрываем и удаляем временный проект
close_project -quiet
file delete -force $Project_Name