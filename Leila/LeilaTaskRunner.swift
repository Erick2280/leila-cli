//
//  Leila.swift
//  Leila
//
//  Created by Erick Almeida on 18/08/20.
//  Copyright © 2020 Erick Almeida. All rights reserved.
//

import Foundation

class LeilaTaskRunner {
    
    private let projectUrl: URL
    private let fileManager: FileManager
    
    public init(fileManager: FileManager, projectLocation: String?) {
        self.fileManager = fileManager
        
        if (projectLocation != nil) {
            self.projectUrl = URL(fileURLWithPath: projectLocation!)
        } else {
            self.projectUrl = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        }
    }
    
    public func addFont(fontPath: String) {
    
        let fontUrl = URL(fileURLWithPath: fontPath)

        if !fileManager.fileExists(atPath: fontUrl.path) {
            fputs("Erro: O arquivo de fonte não existe.", stderr)
            print()
            return
        }

        if !(fontUrl.pathExtension == "ttf" || fontUrl.pathExtension == "otf") {
            fputs("Erro: O arquivo informado não parece ser uma fonte válida.", stderr)
            print()
            print("O arquivo de fonte precisa estar no formato OpenType (otf) ou TrueType (ttf).")
            return
        }
        
        guard let bundle = Bundle.init(path: projectUrl.path) else {
            fputs("Erro: O caminho informado não existe.", stderr)
            print()
            return
        }
        
        guard let plistFile = bundle.path(forResource: "Info", ofType: "plist") else {
            fputs("Erro: O diretório não parece ser um projeto do Xcode.", stderr)
            print()
            print("A pasta executada pelo comando precisa ser a mesma onde está o arquivo \"Info.plist\".")
            return
        }
        
        guard let plistDict = NSMutableDictionary(contentsOfFile: plistFile) else {
            fputs("Erro: Não foi possível abrir o arquivo \"Info.plist\".", stderr)
            print()
            print("Verifique se o arquivo é válido e se seu usuário tem as permissões necessárias para realizar a cópia.")
            return
        }
        
        let fontsPathUrl = projectUrl.appendingPathComponent("Fonts")
        if !fileManager.fileExists(atPath: fontsPathUrl.path) {
            do {
                print("Criando uma pasta Fonts em \(fontsPathUrl.path)...")
                try fileManager.createDirectory(atPath: fontsPathUrl.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fputs("Erro: Não foi possível criar uma pasta Fonts.", stderr)
                print()
                print(error.localizedDescription);
                return
            }
        }
        
        let fontFileName = fontUrl.lastPathComponent;
        
        print("Copiando \(fontFileName) para \(fontsPathUrl.path)...")
        
        do {
            try fileManager.copyItem(atPath: fontUrl.path, toPath: fontsPathUrl.appendingPathComponent(fontFileName).path)
        } catch {
            fputs("Erro: Não foi possível copiar a fonte.", stderr)
            print()
            print(error.localizedDescription);
            return
        }
        
        print("Registrando a fonte no projeto...")
        
        if let plistAppFontsEntry = plistDict.object(forKey: "UIAppFonts") {
            let plistAppFontsArray = plistAppFontsEntry as! NSMutableArray
            plistAppFontsArray.add(fontFileName)
        } else {
            let plistAppFontsArray = NSMutableArray()
            plistAppFontsArray.add(fontFileName)
            plistDict.setValue(plistAppFontsArray, forKey: "UIAppFonts")
        }
        
        plistDict.write(toFile: plistFile, atomically: true)
        
        print("Concluído :)")
    }
    
    public func generateImageSet(assetName: String, assetPath: String) {
        var assetFolderName = assetName
        
        if !(assetFolderName.hasSuffix(".appiconset") || assetFolderName.hasSuffix(".imageset")) {
            assetFolderName += ".imageset"
        }
        
        let assetUrl = URL(fileURLWithPath: assetPath)
        
        let assetFileNameWithoutExtension = assetUrl.deletingPathExtension().lastPathComponent
        let assetFileExtension = assetUrl.pathExtension

        if !fileManager.fileExists(atPath: assetUrl.path) {
            fputs("Erro: O arquivo do asset não existe.", stderr)
            print()
            return
        }

        if (assetFolderName.hasSuffix(".appiconset")) {
            if !(assetUrl.pathExtension == "png") {
                fputs("Erro: O arquivo informado não parece ser uma imagem válida.", stderr)
                print()
                print("O arquivo de imagem para gerar ícones precisa estar no formato PNG.")
                return
            }
        }
        
        if (assetFolderName.hasSuffix(".imageset")) {
            if !(assetUrl.pathExtension == "png") {
                fputs("Erro: O arquivo informado não parece ser uma imagem válida.", stderr)
                print()
                print("O arquivo de imagem precisa estar no formato AVCI, HEIC, HEIF, PNG, JPG ou PDF.")
                return
            }
        }
        
        let assetsUrl = projectUrl.appendingPathComponent("Assets.xcassets")
        
        if !fileManager.fileExists(atPath: assetsUrl.path) {
            fputs("Erro: Não foi possível encontrar o diretório de assets do projeto.", stderr)
            print()
            print("Verifique se o diretório é de um projeto do Xcode.")
            return
        }
        
        let assetFolderUrl = assetsUrl.appendingPathComponent(assetFolderName)
        
        if (assetFolderName.hasSuffix(".imageset")) {
            
            do {
                print("Criando um diretório para o asset \(assetFolderName)...")
                try fileManager.createDirectory(atPath: assetFolderUrl.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fputs("Erro: Não foi possível criar um diretório para o asset.", stderr)
                print()
                print(error.localizedDescription);
                return
            }
            
            print("Redimensionando imagem...")
            
            guard let image3x = getImage(from: assetUrl) else {
                fputs("Erro: Não foi possível carregar a imagem.", stderr)
                print()
                print("Verifique se o arquivo é uma imagem válida.")
                return
            }
            
            let imageWidth1x = image3x.width / 3
            let imageHeight1x = image3x.height / 3
            
            let imageWidth2x = imageWidth1x * 2
            let imageHeight2x = imageHeight1x * 2
            
            guard let image1x = resizedImage(from: image3x, for: CGSize(width: imageWidth1x, height: imageHeight1x)),
                let image2x = resizedImage(from: image3x, for: CGSize(width: imageWidth2x, height: imageHeight2x)) else {
                    fputs("Erro: Não foi possível redimensionar a imagem.", stderr)
                    print()
                    return
            }
            
            print("Copiando imagens geradas para o projeto...")
            
            do {
                let image1xData = getData(from: image1x, fileExtension: assetFileExtension)
                let image2xData = getData(from: image2x, fileExtension: assetFileExtension)
                let image3xData = getData(from: image3x, fileExtension: assetFileExtension)
                try image1xData?.write(to: assetFolderUrl.appendingPathComponent("\(assetFileNameWithoutExtension)@1x.\(assetFileExtension)"))
                try image2xData?.write(to: assetFolderUrl.appendingPathComponent("\(assetFileNameWithoutExtension)@2x.\(assetFileExtension)"))
                try image3xData?.write(to: assetFolderUrl.appendingPathComponent("\(assetFileNameWithoutExtension)@3x.\(assetFileExtension)"))
            } catch {
                fputs("Erro: Não foi possível copiar as imagens para o diretório de destino.", stderr)
                print()
                print(error.localizedDescription);
                return
            }
            
        }
        
        print("Criando arquivo \"Contents.json\"...")
        
        let contentFile: [String: Any] = [ "images": [["filename": "\(assetFileNameWithoutExtension)@1x.\(assetFileExtension)", "idiom": "universal", "scale" : "1x"], ["filename": "\(assetFileNameWithoutExtension)@2x.\(assetFileExtension)", "idiom": "universal", "scale" : "2x"], ["filename": "\(assetFileNameWithoutExtension)@3x.\(assetFileExtension)", "idiom": "universal", "scale" : "3x"]], "info": ["author": "xcode", "version": 1] ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: contentFile, options: [.prettyPrinted])
            try data.write(to: assetFolderUrl.appendingPathComponent("Contents.json"), options: [.atomicWrite])
        } catch {
            fputs("Erro: Não foi possível criar o arquivo \"Contents.json\".", stderr)
            print()
            print(error.localizedDescription);
            return
        }
        
        print("Concluído :)")
        
    }
    
    func getData(from cgImage: CGImage, fileExtension: String) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.\(fileExtension)" as CFString, 1, nil) else {
                return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        
        if CGImageDestinationFinalize(destination) {
            let data = mutableData as Data
            return data
        } else {
            return nil
        }
    }
    
    func getImage(from url: URL) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        
        return image
    }
    
    func resizedImage(from image: CGImage, for size: CGSize) -> CGImage? {
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                            width: Int(size.width),
                                            height: Int(size.height),
                                            bitsPerComponent: image.bitsPerComponent,
                                            bytesPerRow: image.bytesPerRow,
                                            space: colorSpace,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.interpolationQuality = .high
        context?.draw(image, in: CGRect(origin: .zero, size: size))

        guard let scaledImage = context?.makeImage() else { return nil }

        return scaledImage
    }
    
    public func showHelp() {
        print(" _          _        ")
        print("| |     o  | |       ")
        print("| |  _     | |  __,  ")
        print("|/  |/  |  |/  /  |  ")
        print("|__/|__/|_/|__/\\_/|_/")
        print("")
        print("leila v1.0.0")
        print("Ferramenta para auxiliar em tarefas comuns relacionadas à artefatos de projetos do Xcode")
        print()
        print("USO:")
        print("generate <nome-do-asset> <caminho-do-arquivo>")
        print("- Cria um novo conjunto de imagens (imageset) no projeto a partir do arquivo dado.")
        print("- Você pode gerar ícones de aplicativo executando \"generate AppIcon.appiconset\".")
        print()
        print("add-font <caminho-da-fonte>")
        print("- Adiciona uma fonte no projeto a partir do arquivo dado.")
        print()
        print("help")
        print("- Mostra essa ajuda.")
    }
    
    public func showNoSuchCommandError() {
        fputs("Erro: O comando informado não existe.", stderr)
        print()
        print()
        showHelp()
    }
    
    public func showMissingArgumentError(forOption: OptionType) {
        fputs("Erro: O comando não tem todos os argumentos necessários.", stderr)
        switch forOption {
        case .generate:
            print()
            print("O uso esperado desse comando é:")
            print("generate <nome-do-asset> <caminho-do-arquivo>")
        case .addFont:
            print()
            print("O uso esperado desse comando é:")
            print("add-font <caminho-da-fonte>")
        default:
            print()
        }

    }
    
}
