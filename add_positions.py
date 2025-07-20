import json
import random

def add_positions_to_json():
    # JSON dosyasını oku
    with open('assets/json/word_game_lv.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Her seviye için positions ekle
    for level in data:
        words = level['words']
        letters = level['letters'].split(',')
        
        # Her kelime için positions oluştur
        word_positions = {}
        
        for word in words:
            positions = []
            word_upper = word.upper()
            
            # Kelimenin her harfi için rastgele pozisyon oluştur
            for i, letter in enumerate(word_upper):
                # 5x5 grid kullan (0-4 arası koordinatlar)
                row = random.randint(0, 4)
                col = random.randint(0, 4)
                positions.append({"row": row, "col": col})
            
            word_positions[word_upper] = positions
        
        # Seviyeye positions ve grid_size ekle
        level['word_positions'] = word_positions
        level['grid_size'] = [5, 5]  # 5x5 grid
    
    # Güncellenmiş JSON'u kaydet
    with open('assets/json/word_game_lv.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"Positions added to {len(data)} levels successfully!")

if __name__ == "__main__":
    add_positions_to_json() 