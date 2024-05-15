fx_version 'cerulean'
game 'gta5'

description 'Atiya Piano'
version '1.0.2'

client_scripts {
    'client/*.lua'
}
server_scripts {
    'server/*.lua'
}

shared_scripts {
    'shared/*.lua'
}

dependency 'xsound'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js'
}
