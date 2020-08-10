#! /usr/bin/env bash

source ./outil.sh
source ./awklets/pacmd.sh

WOAH='N/A'
while : ; do
    readarray -t SINKS < <(get_combine_sinks)
    resp=$(
        zenity --title='Combine Sink Manager' \
        --list --text='Combine Sinks disponíveis:' --radiolist --column 'Escolha' --column 'Nome interno' --column 'Descrição' --column 'Conectado a' \
        "${SINKS[@]}" \
        'CMD1' 'Criar nova' 'Selecione para criar uma nova sink.' "$WOAH" \
        'CMD2' 'Deletar todas' 'Selecione para REMOVER TODAS AS SINKS.' "$WOAH" \
        'CMD3' 'Gerar arquivo de configuração' 'Cria um arquivo de configuração que é carregado pelo sistema durante a inicialização.' "$WOAH"
    ) || break
    case "$resp" in
        'Criar nova')
            "$CURDIR"/sink-ops.sh create_sink
            ;;
        'Deletar todas')
            "$CURDIR"/sink-ops.sh delete_sink
            ;;
        'Gerar arquivo de configuração')
            gen_pa_commands
            ;;
        '')
            break
            ;;
        *)
            "$CURDIR"/sink-ops.sh sink_dialog "$resp"
            ;;
    esac
done
