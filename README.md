# 2B Afin Dönüşümleri (Ruby)

Bu proje 2B noktalar ve poligonlar üzerinde afin dönüşümleri uygulamakta ve
çıktıları konsol, GUI ve HTML olarak üretmektedir.

## Kurulum

GUI için Ruby2D gereklidir:

```
sudo apt install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
sudo gem install ruby2d
```

## Çalıştırma

Konsol çıktısı:

```
ruby /home/ismylhakki/Documents/Computer-Graphics/main.rb
```

GUI (Ruby2D):

```
ruby /home/ismylhakki/Documents/Computer-Graphics/main.rb --gui
```

HTML çıktı (SVG):

```
ruby /home/ismylhakki/Documents/Computer-Graphics/main.rb --html
```

⭐️ ⭐️ HTML çıktısını tarayıcıda aç (Tavsiye edilen) ⭐️ ⭐️

```
ruby /home/ismylhakki/Documents/Computer-Graphics/main.rb --html --open
```

## Üretilen HTML

Ruby, `affine_view.html` dosyasını üretmektedir. Üretilmiş bir html dosyasını online görüntülemek için aşağıdaki linki kullanabilirsiniz:

[Online görüntüleme için tıklayınız](https://ismailhakkituran.github.io/Affine-Transformations/affine_view.html)

## Neler Gösterilir?

- Orijinal ve dönüşmüş poligonlar grid üzerinde yan yana gösterilir
- Dönüşümler animasyonlu olarak arada geçiş yapar
- Normal dönüşümü için yanlış ve doğru (inverse-transpose) karşılaştırması bulunur

## Normal Dönüşümü (Inverse Transpose) Örneği

Komut satırında yanlış hesaplamayı görmek için:

```
ruby /home/ismylhakki/Documents/Computer-Graphics/main.rb --normal-demo
```
