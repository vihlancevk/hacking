#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>
#include <iostream>
#include <ctime>

void how2timer(int ms) {
    int CLOCKS_PER_MSEC = CLOCKS_PER_SEC / 1000;   // новая константа
    clock_t end_time = clock() + ms * CLOCKS_PER_MSEC ;  // время завершения
    while (clock() < end_time) {}  // цикл ожидания времени
}

int main()
{

    sf::RenderWindow window( sf::VideoMode(1920 , 1080), "", sf::Style::Default );

    sf::Font font;
    if ( !font.loadFromFile( "images/font.ttf" ) )
        std::cout << "Can't find the font file" << std::endl;

    sf::Texture background;
    sf::Sprite backgroundImage;
    if ( !background.loadFromFile( "images/rkn.jpeg" ) )
        std::cout << "Error: Could not display rkn image" << std::endl;
    backgroundImage.setTexture( background, true );
    sf::Vector2f targetSize(1920.0f, 1080.0f);
    float zoomX = targetSize.x / backgroundImage.getLocalBounds().width;
    float zoomY = targetSize.y / backgroundImage.getLocalBounds().height;
    backgroundImage.setScale( zoomX, zoomY );

    sf::Texture button;
    sf::Sprite buttonImage;
    if ( !button.loadFromFile( "images/button.png" ) )
        std::cout << "Can't find the image" << std::endl;
    buttonImage.setPosition( 45.0f, 538.75f );
    buttonImage.setScale( zoomX, zoomY );
    buttonImage.setTexture( button );

    sf::Text buttonText;
    buttonText.setFont( font );
    buttonText.setStyle( sf::Text::Bold );
    buttonText.setString( "Hacking" );
    buttonText.setFillColor( sf::Color::Black );
    buttonText.setCharacterSize( 100 );
    buttonText.setPosition( 300.0f, 650.0f );

    int percent = 100;
    sf::RectangleShape progressbar;
    progressbar.setFillColor(sf::Color::Blue);
    progressbar.setOutlineThickness( 3 );
    progressbar.setPosition( 180.0f, 750.0f );
    progressbar.setOutlineColor(sf::Color::Black);

    sf::Text progressbarText;
    progressbarText.setFont( font );
    progressbarText.setStyle( sf::Text::Bold );
    progressbarText.setFillColor( sf::Color::Black );
    progressbarText.setCharacterSize( 40 );
    
    while ( window.isOpen() )
    {
        sf::Event Event;
        while ( window.pollEvent( Event ) )
        {
            switch ( Event.type )
            {
                case sf::Event::Closed:
                window.close();
                break;
                case sf::Event::MouseMoved:
                {
                    sf::Vector2i mousePos = sf::Mouse::getPosition( window );
                    sf::Vector2f mousePosF( static_cast<float>( mousePos.x ), static_cast<float>( mousePos.y ) );
                    if ( buttonImage.getGlobalBounds().contains( mousePosF ) )
                    {
                        buttonImage.setColor( sf::Color( 250, 20, 20 ) );
                    }
                    else
                    {
                        buttonImage.setColor( sf::Color( 255, 255, 255 ) );
                    }
                }
                break;
                case sf::Event::MouseButtonPressed:
                {
                    sf::Vector2i mousePos = sf::Mouse::getPosition( window );
                    sf::Vector2f mousePosF( static_cast<float>( mousePos.x ), static_cast<float>( mousePos.y ) );
                    if ( buttonImage.getGlobalBounds().contains( mousePosF ) )
                    {
                        buttonImage.setColor( sf::Color( 255, 255, 255 ) );
                        while ( percent > 1 )
                        {
                            progressbar.setSize( sf::Vector2f( (100-percent) * 7, 40) );
                            progressbarText.setPosition( 150.0f + (100-percent) * 7 / 2, 746.0f );
                            progressbarText.setString( std::to_string(100 - percent) + "%" );
                            window.clear();
                            window.draw( backgroundImage );
                            window.draw( progressbar );
                            window.draw( progressbarText );
                            window.display();
                            percent--;
                            how2timer(100);
                        }
                        system ( "vlc -f --no-video-title-show --play-and-exit videos/rkn.mp4" );
                        window.close();
                    }
                }
                break;
            }
        }

    window.clear();
    window.draw( backgroundImage );
    window.draw( buttonImage );
    window.draw( buttonText );
    window.display();
    }

  return 0;
}