class GreetingService {


  String getGreeting(String name) {

    final hour = DateTime.now().hour;


    if (hour >= 6 && hour < 12) {

      return "☀️ Günaydın $name";

    }


    if (hour >= 12 && hour < 18) {

      return "🌤️ İyi günler $name";

    }


    if (hour >= 18 && hour < 24) {

      return "🌙 İyi akşamlar $name";

    }


    return "🌌 Geç saatlerde buradasın $name";

  }



  String getMessage() {

    final hour = DateTime.now().hour;


    if (hour >= 6 && hour < 12) {

      return "Bugün hedeflerin için küçük bir adım atmaya ne dersin?";

    }


    if (hour >= 12 && hour < 18) {

      return "Günün nasıl gidiyor? Biraz kendine zaman ayırmayı unutma.";

    }


    if (hour >= 18 && hour < 24) {

      return "Bugünü değerlendirmek ve yarını planlamak için güzel bir zaman.";

    }


    return "Gece sakin düşünceler için güzel olabilir.";

  }


}