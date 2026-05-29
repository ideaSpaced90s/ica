class ChessPiecePaths {
  // Rather than simple string replacements, we now use distinct SVG paths/designs for the themes.
  // We'll define a few distinct "families" of pieces to fulfill the request.

  static String getPiecePath(String type, String themeName) {
    // Family map
    switch (themeName) {
      case 'Anime Ink':
        return _getInkPath(type);
      case 'Fairytale Castle':
        return _getFairytalePath(type);
      case 'Animal Friends':
        return _getAnimalFriendsPath(type);
      default:
        return _getClassicPath(type);
    }
  }

  // --- CLASSIC (Base shape, cleanly scaled) ---
  static String _getClassicPath(String type) {
    switch (type) {
      case 'king':
        return '''
          <g>
            <path d="M22.5 11.63V6M20 8h5" fill="none" stroke="{secondary}" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M22.5 25s4.5-7.5 5.8-10.5c.8-1.9.4-4-1.3-4.5-1.9-.5-3.3 1-3.3 1s-1-1.5-1.2-1.5c-.2 0-1.2 1.5-1.2 1.5s-1.4-1.5-3.3-1c-1.7.5-2.1 2.6-1.3 4.5 1.3 3 5.8 10.5 5.8 10.5z" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11.5 37c5.5 3.5 15.5 3.5 21 0v-7s9-4.5 6-10.5c-4-6.5-13.5-3.5-16 4V27v-3.5c-3.5-7.5-13-10.5-16-4-3 6 5 10.5 5 10.5v7z" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11.5 30c5.5-3 15.5-3 21 0m-21 3.5c5.5-3 15.5-3 21 0m-21 3.5c5.5-3 15.5-3 21 0" fill="none" stroke="{secondary}" stroke-linejoin="miter" stroke-width="1.5" />
          </g>
        ''';
      case 'queen':
        return '''
          <g>
            <path d="M9 26c8.5-1.5 21-1.5 27 0l2-12-7 11V11l-5.5 13.5-3-15-3 15-5.5-14V25L7 14l2 12z" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M9 26c0 2 1.5 2 2.5 4 1 1.5 1 1 .5 3.5-1.5 1-1.5 2.5-1.5 2.5-1.5 1.5.5 2.5.5 2.5 6.5 1 16.5 1 23 0 0 0 1.5-1 0-2.5 0 0 .5-1.5-1-2.5-.5-2.5-.5-2 .5-3.5 1-2 2.5-2 2.5-4-8.5-1.5-21-1.5-27 0z" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11 38.5a35 35 0 0 0 23 0" fill="none" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11 29a35 35 0 0 1 23 0M12.5 31.5h20M11.5 34.5a35 35 0 0 0 22 0" fill="none" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <circle cx="7" cy="14" r="2" fill="{primary}" stroke="{secondary}" stroke-width="1.5" />
            <circle cx="14" cy="11" r="2" fill="{primary}" stroke="{secondary}" stroke-width="1.5" />
            <circle cx="22.5" cy="9.5" r="2" fill="{primary}" stroke="{secondary}" stroke-width="1.5" />
            <circle cx="31" cy="11" r="2" fill="{primary}" stroke="{secondary}" stroke-width="1.5" />
            <circle cx="38" cy="14" r="2" fill="{primary}" stroke="{secondary}" stroke-width="1.5" />
          </g>
        ''';
      case 'rook':
        return '''
          <g>
            <path d="M9 39h27v-3H9v3zM12 36v-4h21v4H12zM11 14V9h4v2h5V9h5v2h5V9h4v5" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M34 14l-3 3H14l-3-3" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M31 17v12.5H14V17" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M31 29.5l1.5 2.5h-20l1.5-2.5" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11 14h23" fill="none" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
          </g>
        ''';
      case 'bishop':
        return '''
          <g>
            <g fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5">
              <path d="M9 36c3.39-.97 10.11.43 13.5-2 3.39 2.43 10.11 1.03 13.5 2 0 0 1.65.54 3 2-.68.97-1.65.99-3 .5-3.39-.97-10.11.46-13.5-1-3.39 1.46-10.11.03-13.5 1-1.354.49-2.323.47-3-.5 1.354-1.94 3-2 3-2z" />
              <path d="M15 32c2.5 2.5 12.5 2.5 15 0 .5-1.5 0-2 0-2 0-2.5-2.5-4-2.5-4 5.5-1.5 6-11.5-5-15.5-11 4-10.5 14-5 15.5 0 0-2.5 1.5-2.5 4 0 0-.5.5 0 2z" />
              <path d="M25 8a2.5 2.5 0 1 1-5 0 2.5 2.5 0 1 1 5 0z" />
            </g>
            <path d="M17.5 26h10M15 30h15m-7.5-14.5v5M20 18h5" fill="none" stroke="{secondary}" stroke-linejoin="miter" stroke-width="1.5" />
          </g>
        ''';
      case 'knight':
        return '''
          <g>
            <path d="M22 10c10.5 1 16.5 8 16 29H15c0-9 10-6.5 8-21" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M24 18c.38 2.91-5.55 7.37-8 9-3 2-2.82 4.34-5 4-1.042-.94 1.41-3.04 0-3-1 0 .19 1.23-1 2-1 0-4.003-1-4-4 0-2 6-12 6-12s1.89-1.9 2-3.5c-.73-.994-.5-2-.5-3 1-1 3 2.5 3 2.5h2s.78-1.992 2.5-3c1 0 1 3 1 3" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M9.5 25.5a.5.5 0 1 1-1 0 .5.5 0 1 1 1 0z" fill="{secondary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M15 15.5a.5.5 0 1 1-1 0 .5.5 0 1 1 1 0z" fill="{secondary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
          </g>
        ''';
      case 'pawn':
        return '''
          <g>
            <path d="M22 9c-2.21 0-4 1.79-4 4 0 3.15 2.5 4.5 3 6.5-3.1 1.05-6 2.95-6 6 0 2 1.5 2.5 2.5 3 1 1 3 1 4.5 1.5 1.5.5 2.5 1.5 2.5 1.5s1-1 2.5-1.5c1.5-.5 3.5-.5 4.5-1.5 1-.5 2.5-1 2.5-3 0-3.05-2.9-4.95-6-6 .5-2 3-3.35 3-6.5 0-2.21-1.79-4-4-4z" fill="{primary}" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11 38.5a35 35 0 0 0 23 0" fill="none" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
            <path d="M11 29a35 35 0 0 1 23 0M12.5 31.5h20M11.5 34.5a35 35 0 0 0 22 0" fill="none" stroke="{secondary}" stroke-linecap="butt" stroke-linejoin="miter" stroke-width="1.5" />
          </g>
        ''';
      default: return '';
    }
  }



  // --- ANIME INK (Heavy hand-drawn curves, variable stroke thickness) ---
  static String _getInkPath(String type) {
    // Thick black stylized strokes mimicking a brush pen
    switch (type) {
      case 'king':
        return '<path d="M22 4c2 0 4 2 2 5h4c1 4-2 6-4 6v8c5 2 8 8 8 12H12c0-4 3-10 8-12v-8c-2 0-5-2-4-6h4C18 6 20 4 22 4z" fill="{primary}" stroke="{secondary}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'queen':
        return '<path d="M10 10c2 5 6 8 12 8s10-3 12-8c-2 8-5 14-6 25H16c-1-11-4-17-6-25z" fill="{primary}" stroke="{secondary}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>';
      case 'rook':
        return '<path d="M10 10h6v6h6v-6h6v6h6v25H10V10z" fill="{primary}" stroke="{secondary}" stroke-width="3" stroke-linejoin="round"/>';
      case 'bishop':
        return '<path d="M22 6c-8 8-4 18 0 20v9H16v-6l6-2v8l6-6v6h-6v-9c4-2 8-12 0-20z" fill="{primary}" stroke="{secondary}" stroke-width="3" stroke-linejoin="round"/>';
      case 'knight':
        return '<path d="M14 35c2-10-2-15 4-20 8-6 12 2 8 10h4c0 10-6 15-8 10-2 8 4 10-4 0z" fill="{primary}" stroke="{secondary}" stroke-width="3" stroke-linejoin="round"/>';
      case 'pawn':
        return '<path d="M22 10c-3 0-6 3-6 6 0 4 3 6 4 8-3 2-6 6-6 10h16c0-4-3-8-6-10 1-2 4-4 4-8 0-3-3-6-6-6z" fill="{primary}" stroke="{secondary}" stroke-width="3" stroke-linejoin="round"/>';
      default: return '';
    }
  }

  // --- FAIRYTALE (Princesses, magic, cute wizard hats/crowns for kids) ---
  static String _getFairytalePath(String type) {
    switch (type) {
      case 'king':
        return '''
          <g>
            <path d="M12 36h21v4H12zm2-20l3 12h11l3-12-6 8-4-12-4 12z" fill="{primary}" stroke="{secondary}" stroke-width="2" stroke-linejoin="round"/>
            <circle cx="22.5" cy="11" r="3" fill="{secondary}" />
            <path d="M22.5 32c-2-2-4-1-4 1s2 3 4 4c2-1 4-2 4-4s-2-3-4-1z" fill="{secondary}"/>
          </g>
        ''';
      case 'queen':
        return '''
          <g>
            <path d="M10 36h25v4H10zm4-16l4 10h9l4-10-6 6-4-12-4 12z" fill="{primary}" stroke="{secondary}" stroke-width="2" stroke-linejoin="round"/>
            <path d="M8 24c-3-3-4-7-1-9s7 1 6 5m22 0c3-3 4-7 1-9s-7 1-6 5" fill="none" stroke="{secondary}" stroke-width="1.8"/>
            <polygon points="22.5,5 24,9 28,9 25,12 26,16 22.5,14 19,16 20,12 17,9 21,9" fill="{secondary}"/>
          </g>
        ''';
      case 'knight':
        return '''
          <g>
            <path d="M33 38c0-8-2-15-10-18-2-1-5-2-7-1-1 .5-2 1.5-2 3v2c0 2-2 4-4 4s-4-2-4-4c0-4 4-8 8-8h3c6 0 12 4 15 11l1 12z" fill="{primary}" stroke="{secondary}" stroke-width="2" stroke-linejoin="round"/>
            <circle cx="18" cy="22" r="3.5" fill="{secondary}"/>
            <circle cx="17.2" cy="21.2" r="1.2" fill="{primary}"/>
            <path d="M13 29q3 2 6 0" fill="none" stroke="{secondary}" stroke-width="1.5" stroke-linecap="round"/>
            <path d="M21 12l2-5 3 4z" fill="{primary}" stroke="{secondary}" stroke-width="1.8"/>
          </g>
        ''';
      case 'bishop':
        return '''
          <g>
            <path d="M12 36h21v4H12zm2-4c2-5 6-18 8.5-24 2.5 6 6.5 19 8.5 24z" fill="{primary}" stroke="{secondary}" stroke-width="2" stroke-linejoin="round"/>
            <circle cx="22.5" cy="5" r="3.5" fill="{secondary}"/>
            <path d="M15 32c4-2 11-2 15 0" fill="none" stroke="{secondary}" stroke-width="2"/>
          </g>
        ''';
      case 'rook':
        return '''
          <g>
            <path d="M12 38h21v3H12zm2-22v22h17V16l-3 3v-6h-3v6h-5v-6h-3v6z" fill="{primary}" stroke="{secondary}" stroke-width="2" stroke-linejoin="round"/>
            <circle cx="22.5" cy="26" r="3" fill="{secondary}"/>
          </g>
        ''';
      case 'pawn':
      default:
        return '''
          <g>
            <path d="M15 38c0-5 3-12 7.5-12s7.5 7 7.5 12z" fill="{primary}" stroke="{secondary}" stroke-width="2" stroke-linejoin="round"/>
            <circle cx="22.5" cy="18" r="6" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="20.5" cy="17" r="0.8" fill="{secondary}"/>
            <circle cx="24.5" cy="17" r="0.8" fill="{secondary}"/>
            <path d="M21.5 20q1 1 2 0" fill="none" stroke="{secondary}" stroke-width="1" stroke-linecap="round"/>
          </g>
        ''';
    }
  }

  // --- ANIMAL FRIENDS (Cute animal faces for kids) ---
  static String _getAnimalFriendsPath(String type) {
    switch (type) {
      case 'king':
        return '''
          <g>
            <circle cx="22.5" cy="26" r="11" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="12.5" cy="17" r="4" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="32.5" cy="17" r="4" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <path d="M18 13l2-4 2.5 3 2.5-3 2 4z" fill="{secondary}" stroke="{secondary}" stroke-width="1"/>
            <circle cx="19.5" cy="24" r="1.2" fill="{secondary}"/>
            <circle cx="25.5" cy="24" r="1.2" fill="{secondary}"/>
            <ellipse cx="22.5" cy="27.5" rx="1.8" ry="1" fill="{secondary}"/>
            <path d="M21.5 29.5q1 1 2 0" fill="none" stroke="{secondary}" stroke-width="1.2"/>
            <path d="M14 36h17v4H14z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
          </g>
        ''';
      case 'queen':
        return '''
          <g>
            <circle cx="22.5" cy="27" r="9.5" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <path d="M17 19c-1-5-1-12 1.5-14s3.5 4 2.5 10zm11 0c1-5 1-12-1.5-14s-3.5 4-2.5 10z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="22.5" cy="18" r="2.2" fill="{secondary}"/>
            <polygon points="22.5,18 19,16 19,20" fill="{secondary}"/>
            <polygon points="22.5,18 26,16 26,20" fill="{secondary}"/>
            <circle cx="19.5" cy="26" r="1" fill="{secondary}"/>
            <circle cx="25.5" cy="26" r="1" fill="{secondary}"/>
            <circle cx="22.5" cy="28.5" r="1" fill="{secondary}"/>
            <path d="M21.5 30.5q1 1 2 0" fill="none" stroke="{secondary}" stroke-width="1"/>
            <path d="M14 36h17v4H14z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
          </g>
        ''';
      case 'knight':
        return '''
          <g>
            <path d="M13 36c0-7 2-12 9.5-12s9.5 5 9.5 12z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="22.5" cy="21" r="8" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <path d="M15 17c-2 2-3 8-1 10s3-4 2-8zm15 0c2 2 3 8 1 10s-3-4-2-8z" fill="{secondary}" stroke="{secondary}" stroke-width="1.5"/>
            <circle cx="19.5" cy="20" r="1" fill="{secondary}"/>
            <circle cx="25.5" cy="20" r="1" fill="{secondary}"/>
            <ellipse cx="22.5" cy="23" rx="2" ry="1.2" fill="{secondary}"/>
            <path d="M21.5 25.5q1 1 2 0" fill="none" stroke="{secondary}" stroke-width="1"/>
            <path d="M14 36h17v4H14z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
          </g>
        ''';
      case 'bishop':
        return '''
          <g>
            <path d="M14 36h17v4H14zm8.5-22c-6 0-10 4-10 12s4 10 10 10 10-2 10-10-4-12-10-12z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="18" cy="22" r="3.5" fill="{primary}" stroke="{secondary}" stroke-width="1.5"/>
            <circle cx="27" cy="22" r="3.5" fill="{primary}" stroke="{secondary}" stroke-width="1.5"/>
            <circle cx="18" cy="22" r="1.5" fill="{secondary}"/>
            <circle cx="27" cy="22" r="1.5" fill="{secondary}"/>
            <polygon points="22.5,24 21,26 24,26" fill="{secondary}"/>
            <path d="M13 15l3 3m16-3l-3 3" stroke="{secondary}" stroke-width="2" stroke-linecap="round"/>
          </g>
        ''';
      case 'rook':
        return '''
          <g>
            <path d="M14 36h17v4H14zm8.5-18c-6 0-9.5 4-9.5 11s3.5 9 9.5 9 9.5-2 9.5-9-3.5-11-9.5-11z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <polygon points="14,19 11,11 18,17" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <polygon points="31,19 34,11 27,17" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <circle cx="18.5" cy="23" r="1" fill="{secondary}"/>
            <circle cx="26.5" cy="23" r="1" fill="{secondary}"/>
            <polygon points="22.5,25 21.5,24 23.5,24" fill="{secondary}"/>
            <path d="M13 25h3m-3 2h3m10-2h3m-3 2h3" stroke="{secondary}" stroke-width="1" stroke-linecap="round"/>
          </g>
        ''';
      case 'pawn':
      default:
        return '''
          <g>
            <circle cx="22.5" cy="27" r="8" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
            <path d="M14.5 27c-1-2-1-4 1-4m16 4c1-2 1-4-1-4" fill="none" stroke="{secondary}" stroke-width="1.5"/>
            <circle cx="20" cy="25" r="0.8" fill="{secondary}"/>
            <circle cx="25" cy="25" r="0.8" fill="{secondary}"/>
            <polygon points="22.5,26 21,28 24,28" fill="{secondary}"/>
            <path d="M16 35h13v4H16z" fill="{primary}" stroke="{secondary}" stroke-width="2"/>
          </g>
        ''';
    }
  }
}
