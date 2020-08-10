#! /usr/bin/env bash
# Comandos para processar a saída do pacmd com AWK

# Função base - argumento 
sink_data_get() (
    cd awklets
    pacmd list-sinks | awk '
    @include "sink-data-get.awk"
    function data_get() {
        '"$1"'
    }'
)

# Dá todas as combine sinks, com exceção das que estão nos argumentos
get_combine_sinks() {
    sink_data_get \
    'if (driver=="module-combine-sink.c") {
        print sinknum; print name; print desc; print slave
    }'
}

# Dá todos os dispositivos reais
get_real_sinks() {
    sink_data_get \
    'if (driver=="module-alsa-card.c" || driver=="module-oss.c" || driver=="module-solaris.c" || driver=="module-waveout.c") { 
        print sinknum; print name; print desc; print slave;
    }'
}

# Dá todos os dispositivos virtuais - argumento é o nome interno
get_combine_sink_data() {
    sink_data_get \
    'if (name=="'"$1"'") {
        print sinknum; print name; print desc; print driver; print module_id; print slave;
    }'
}

# Gerar comandos do pulseaudio
gen_pa_commands() {
    local cmd1
    local cmd2
    local datum
    local sinkn
    readarray -t CSINKS < <(get_combine_sinks)
    i=0
    echo -n > ~/.config/pulse/csm.pa
    cmd1=''
    cmd2=''
    for datum in "${CSINKS[@]}"; do
        i=$((i%4))
        case $i in
            0) #índice, nem ligo, só imprime o anterior
                echo "$cmd1" >> ~/.config/pulse/csm.pa
                echo "$cmd2" >> ~/.config/pulse/csm.pa
                cmd1='load-module module-combine-sink'
                cmd2=''
                ;;
            1) # nome
                sinkn="$datum"
                cmd1="${cmd1} sink_name=\"${sinkn}\""
                ;;
            2)
                cmd2="update-sink-proplist ${sinkn} device.description=\"${datum}\"" 
                ;;
            3) # saídas
                test "$datum" = "Nenhuma saída associada." && datum=''
                cmd1="${cmd1} slaves=\"${datum}\""
                ;;
        esac
        let i++
    done
    echo "$cmd1" >> ~/.config/pulse/csm.pa
    echo "$cmd2" >> ~/.config/pulse/csm.pa # Copia o último canal
    if zenity --title='Prévia do arquivo' --text-info --filename="$HOME/.config/pulse/csm.pa"; then
        [ -f ~/.config/pulse/default.pa ] || { [ -f /etc/pulse/default.pa ] && echo '.include /etc/pulse/default.pa' >> ~/.config/pulse/default.pa; }
        grep "^.include $HOME/.config/pulse/csm.pa$" ~/.config/pulse/default.pa || echo "
.include $HOME/.config/pulse/csm.pa" >> ~/.config/pulse/default.pa
    fi
}
