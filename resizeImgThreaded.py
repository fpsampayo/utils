# -*- coding: utf8 -*-

import os
import sys
import threading
from PIL import Image


class ResizeImg(threading.Thread):

    def __init__(self, imagen):
        threading.Thread.__init__(self)
        self.imagen = imagen


    def run(self):

    img = Image.open(imagen)

    w, h = img.size
    #print w
    #print h
    aRatio = float(w)/float(h)
    #print aRatio

    width = 600
    height = int(width / aRatio)
    #print "Se genera imagen " + str(width) + "x" + str(height)

    newImg = img.resize((width, height), Image.ANTIALIAS)
    newImg.save(imagen)



def buscaJpg(baseDir):

    matches = []
    for root, dirnames, filenames in os.walk(baseDir):
        for filename in filenames:
            if os.path.splitext(filename)[1] == '.jpg' or \
                    os.path.splitext(filename)[1] == '.JPG':
                matches.append(os.path.join(root, filename))
    return matches


def main(baseDir):

    ficheros = buscaJpg(baseDir)

    NumeroFicheros = len(ficheros)
    ficheroActual = 0

    for imagen in ficheros:
        ficheroActual =+ 1
        print "[" + ficheroActual + "/" + NumeroFicheros + "]" +" Procesando imagen " + imagen
        t = ResizeImg(imagen)
        t.start()
        t.join()

    print "Proceso finalizado!"


if (len(sys.argv) < 2):
    print """
    Script para redimensionar imagenes de forma masiva.
    OJO! Modifica los ficheros originales!

    Uso: resizeImg.py directorio_para_buscar_imagenes

"""
    sys.exit(2)
else:
    baseDir = sys.argv[1]
    main(baseDir)
