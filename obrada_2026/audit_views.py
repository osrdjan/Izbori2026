from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
root=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
ids=['UZ2','UZ5','UZ24','UZ28','UZ32','UZ34','UZ36','UZ42','UZ43','UZ45','UZ46','UZ47','UZ49','UZ52','UZ53','UZ55','UZ58','UZ63','UZ67','UZ71','UZ74','UZ77','UZ78','SE4']
for b in range(0,len(ids),8):
    sheet=Image.new('RGB',(8*280,1120),'white');d=ImageDraw.Draw(sheet)
    for k,id in enumerate(ids[b:b+8]):
        im=Image.open(root/('full_'+id+'.png'));w,h=im.size;x=k*280
        d.text((x+10,5),id,font=font,fill='black')
        for box,y,size in [((.23,.20,.48,.40),35,(275,230)),((.31,.73,.49,.96),270,(275,290)),((.81,.08,.99,.30),570,(275,360))]:
            a=im.crop(tuple(int(v*(w if i%2==0 else h)) for i,v in enumerate(box)));a.thumbnail(size);sheet.paste(a,(x,y))
    sheet.save(root/('audit_%d.png'%(b//8)))
