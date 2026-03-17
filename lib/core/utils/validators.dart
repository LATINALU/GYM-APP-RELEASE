/// Input validators for forms and use cases
class Validators {
  Validators._();

  /// Validates email format
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates password strength
  /// Requirements: min 8 chars, at least 1 letter and 1 number
  static bool isValidPassword(String? password) {
    if (password == null || password.length < 8) return false;
    
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    
    return hasLetter && hasNumber;
  }

  /// Validates strong password
  /// Requirements: min 8 chars, uppercase, lowercase, number, special char
  static bool isStrongPassword(String? password) {
    if (password == null || password.length < 8) return false;
    
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
    
    return hasUppercase && hasLowercase && hasNumber && hasSpecial;
  }

  /// Validates name (not empty, reasonable length)
  static bool isValidName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    return name.trim().length >= 2 && name.length <= 50;
  }

  /// Validates phone number (basic)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    
    // Remove common formatting characters
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Should be 10-15 digits
    return cleaned.length >= 10 && 
           cleaned.length <= 15 && 
           RegExp(r'^[0-9]+$').hasMatch(cleaned);
  }

  /// Validates gym code format
  static bool isValidGymCode(String? code) {
    if (code == null || code.isEmpty) return false;
    
    // Must be 4-10 uppercase alphanumeric characters
    return code.length >= 4 && 
           code.length <= 10 && 
           RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase());
  }

  /// Returns password strength score (0-4)
  static int getPasswordStrength(String? password) {
    if (password == null || password.isEmpty) return 0;
    
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    return score.clamp(0, 4);
  }

  /// Get user-friendly error message for email validation
  static String? getEmailError(String? email) {
    if (email == null || email.isEmpty) {
      return 'El correo es requerido';
    }
    if (!isValidEmail(email)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  /// Get user-friendly error message for password validation
  static String? getPasswordError(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Debe incluir al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  /// Get user-friendly error message for gym code validation
  static String? getGymCodeError(String? code) {
    if (code == null || code.isEmpty) {
      return null; // Optional field
    }
    if (code.length < 4) {
      return 'El código debe tener al menos 4 caracteres';
    }
    if (code.length > 10) {
      return 'El código no puede tener más de 10 caracteres';
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(code)) {
      return 'Solo letras y números permitidos';
    }
    return null;
  }
}

/// Simple email validator helper class
class EmailValidator {
  static bool isValid(String? email) => Validators.isValidEmail(email);
}

/// Simple password validator helper class
class PasswordValidator {
  static bool isValid(String? password) => Validators.isValidPassword(password);
  static bool isStrong(String? password) => Validators.isStrongPassword(password);
  
  /// Returns error message if invalid, null if valid
  static String? validate(String? password) => Validators.getPasswordError(password);
}
