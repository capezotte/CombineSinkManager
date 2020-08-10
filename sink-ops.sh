#! /usr/bin/env bash
source ./outil.sh
source ./awklets/pacmd.sh

ZENITY_WARN_ARGS='--title Certeza? --warning --no-wrap'
ZENITY_ERR_ARGS='--title Erro --error'

edit_desc() {
    local DESCR
    DESCR=$(zenity --title="$2 Combine Sink" --text='Descrição da Combine Sink (nome no painel de controle):' --entry) || exit 1
    pacmd update-sink-proplist "$1" device.description=\""$DESCR"\" || { zenity --title 'Erro' --error --text='Descrição inválida'; exit 1; }
}

# Propõe diálogos para a criação de uma nova sink
create_sink() {
    local TITLE
    local OUTS
    declare -a DEFFOSINKS
    TITLE=$(zenity --title='Nova Combine Sink' --text='Nome interno da Combine Sink (não pode ser alterado):' --entry) || exit 1
    TITLE=$(tr -Cd '[:alnum:]' <<<"$TITLE")
    test -z "$TITLE" && { zenity $ZENITY_ERR_ARGS --text='Nome inválido.'; exit 1 ; }
    readarray -t DEFFOSINKS < <( { get_real_sinks; get_combine_sinks; })    
    OUTS=$(
        zenity --title='Mudar saída definitiva' \
        --list --text='Saídas definitivas disponíveis: (a saída padrão é "'"$DEFAULT_SINK"'")' --checklist --column 'Escolha' --column 'Nome' --column 'Descrição' --column 'Conectado a' \
        "${DEFFOSINKS[@]}" \
        | tr '\n' ',' | sed 's/,$//g'
    )
    if test "$OUTS" = ""; then
        zenity $ZENITY_WARN_ARGS --text='Você não selecionou nenhuma saída.
        A saída virtual será muda para você e só poderá ser coletada por outros programas.
        Ao clicar em OK, essa mudança será aplicada.' && OUTS='' || exit 1
    fi
    pacmd load-module module-combine-sink sink_name="$TITLE" slaves="$OUTS"
    edit_desc "$TITLE" || exit 1
    exit 0
}

# Deletar sink
delete_sink() {
        if [ $# -eq 0 ]; then
        zenity $ZENITY_WARN_ARGS --text='Ao clicar OK, todas as Combine Sinks serão apagadas.' && pacmd unload-module module-combine-sink
    else
        if zenity $ZENITY_WARN_ARGS --text='Ao clicar OK, as seguintes Combine Sinks serão apagadas:
'"$@"; then
            for sink in "$@"; do
                pacmd unload-module "$(get_combine_sink_data "$sink" | sed -n 5p)"
            done
        fi
    fi
}

sink_dialog() {
    resp=$(
        zenity --title='Opções de Sink' \
        --list --text='Ações disponíveis para a sink '"$1"':' --radiolist --column 'Escolha' --column 'Descrição' \
        'CMD1' 'Editar descrição' \
        'CMD3' 'Deletar sink'
    )
    case "$resp" in
        'Editar descrição')
            "$CURDIR"/sink-ops.sh edit_desc "$1" Editar
            ;;
        'Deletar sink')
            "$CURDIR"/sink-ops.sh delete_sink "$1"
            ;;
    esac
}

"$@"
