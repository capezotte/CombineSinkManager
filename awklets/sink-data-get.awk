@include "trim.awk"

function clear_vars() {
    name="" # Nome interno da sink
    driver="" # Driver do pulseaudio que controla a sink
    module_id="" # nem eu sei
    slave="" # Saída definitiva de uma combine sink
    desc="" # Descrição ("nome real") da sink.
}

BEGIN {
    FS=OFS="[=:]"
    sinknum=-1
    clear_vars()
}

function pre_data_get() {
    if (driver=="module-combine-sink.c" && slave=="") {
        slave="Nenhuma saída associada."
    }
}

/index:/ {
    pre_data_get()
    data_get()
    sinknum=trim($2)
    clear_vars() # Nova Sink Vindo!
}   
/name:/ {
    name=trim($2)
    name=gensub(/(^<|>$)/,"","g",name)
}
/driver:/ {
    driver=trim($2)
    driver=gensub(/(^<|>$)/,"","g",driver)
    if (driver=="module-alsa-card.c" || driver=="module-oss.c" || driver=="module-solaris.c" || driver=="module-waveout.c") { # É um dispositivo real
        slave="É uma placa real"
    }
    if (driver=="module-null-sink.c") {
        slave="Finalmente o Sol Buraco Negro veio!"
    }
}
/device.description =/ {
    desc=trim($2)
    desc=gensub(/(^"|"$)/,"","g",desc)
}

/combine.slaves/ {
    slave=trim($2)
    slave=gensub(/(^"|"$)/,"","g",slave)
}
/module/ {
    module_id=trim($2)
    module_id=gensub(/(^"|"$)/,"","g",module_id)
}

END {
    pre_data_get()
    data_get()
}
